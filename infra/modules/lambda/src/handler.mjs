import {
  DescribeServiceRevisionsCommand,
  DescribeTasksCommand,
  ECSClient,
  ListTasksCommand,
} from "@aws-sdk/client-ecs";
import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";

import { checkHealth } from "./health-check.mjs";

const defaultEcsClient = new ECSClient({});
const defaultSnsClient = new SNSClient({});

/**
 * Crea un handler inyectable para probar el contrato ECS sin acceder a AWS.
 */
export function createHandler({
  ecsClient = defaultEcsClient,
  snsClient = defaultSnsClient,
  fetchImpl = fetch,
  logger = console,
  alertTopicArn = process.env.ALERT_TOPIC_ARN,
} = {}) {
  return async function deploymentValidator(event) {
    const config = readConfiguration(event);
    const attempt = config.attempt;

    try {
      validateEvent(event);

      const targets = await findTargetTasks(event, ecsClient);
      const checks = targets.flatMap((target) =>
        buildChecks(target.privateIp, config),
      );

      const results = await Promise.all(
        checks.map((check) => checkHealth({ ...check, fetchImpl })),
      );

      logger.info(JSON.stringify({
        message: "Deployment validation succeeded",
        executionId: event.executionId,
        serviceArn: event.executionDetails.serviceArn,
        targetServiceRevisionArn:
          event.executionDetails.targetServiceRevisionArn,
        attempt,
        checks: results,
      }));

      return {
        hookStatus: "SUCCEEDED",
        reason: `${results.length} checks passed on ${targets.length} target task(s)`,
      };
    } catch (error) {
      const failure = serializeError(error);

      logger.error(JSON.stringify({
        message: "Deployment validation failed",
        executionId: event?.executionId,
        attempt,
        maxAttempts: config.maxAttempts,
        error: failure,
      }));

      if (attempt < config.maxAttempts) {
        return {
          hookStatus: "IN_PROGRESS",
          callBackDelay: config.callbackDelay,
          reason: `Validation attempt ${attempt}/${config.maxAttempts} failed: ${failure.message}`,
          hookDetails: {
            attempt: attempt + 1,
          },
        };
      }

      await publishFailureAlert({
        snsClient,
        alertTopicArn,
        event,
        attempt,
        failure,
        logger,
      });

      return {
        hookStatus: "FAILED",
        reason: `Validation failed after ${attempt} attempt(s): ${failure.message}`,
      };
    }
  };
}

export const handler = createHandler();

function readConfiguration(event) {
  let details = event?.hookDetails ?? {};

  if (typeof details === "string") {
    try {
      details = JSON.parse(details);
    } catch {
      details = {};
    }
  }

  const attempt = positiveInteger(details.attempt, 1);
  const maxAttempts = positiveInteger(details.maxAttempts, 3);
  const callbackDelay = positiveInteger(details.callbackDelay, 30);
  const port = positiveInteger(details.port, 8080);
  const timeoutMs = positiveInteger(details.timeoutMs, 3000);

  return {
    attempt,
    maxAttempts,
    callbackDelay,
    port,
    timeoutMs,
    healthPath: normalizePath(details.healthPath ?? "/health"),
    expectedBody:
      details.expectedBody === undefined ? "OK" : details.expectedBody,
    smokePaths: Array.isArray(details.smokePaths)
      ? details.smokePaths.map(normalizePath)
      : [],
  };
}

function positiveInteger(value, fallback) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function normalizePath(path) {
  if (typeof path !== "string" || path.trim() === "") {
    throw new TypeError("Los paths de validacion deben ser strings no vacios");
  }

  return path.startsWith("/") ? path : `/${path}`;
}

function validateEvent(event) {
  if (event?.lifecycleStage !== "POST_SCALE_UP") {
    throw new TypeError("La Lambda solo admite el lifecycle stage POST_SCALE_UP");
  }

  if (!event?.executionDetails?.serviceArn) {
    throw new TypeError("El evento no contiene executionDetails.serviceArn");
  }

  if (!event?.executionDetails?.targetServiceRevisionArn) {
    throw new TypeError(
      "El evento no contiene executionDetails.targetServiceRevisionArn",
    );
  }
}

async function findTargetTasks(event, ecsClient) {
  const { serviceArn, targetServiceRevisionArn } = event.executionDetails;

  const revisionResponse = await ecsClient.send(
    new DescribeServiceRevisionsCommand({
      serviceRevisionArns: [targetServiceRevisionArn],
    }),
  );
  const revision = revisionResponse.serviceRevisions?.[0];

  if (!revision?.clusterArn || !revision?.taskDefinition) {
    throw new Error("ECS no devolvio la revision objetivo solicitada");
  }

  const serviceName = serviceArn.split("/").at(-1);
  const listResponse = await ecsClient.send(
    new ListTasksCommand({
      cluster: revision.clusterArn,
      serviceName,
      desiredStatus: "RUNNING",
    }),
  );

  if (!listResponse.taskArns?.length) {
    throw new Error("La revision nueva todavia no tiene tasks RUNNING");
  }

  const tasksResponse = await ecsClient.send(
    new DescribeTasksCommand({
      cluster: revision.clusterArn,
      tasks: listResponse.taskArns,
    }),
  );

  const targets = (tasksResponse.tasks ?? [])
    .filter(
      (task) =>
        task.lastStatus === "RUNNING" &&
        task.taskDefinitionArn === revision.taskDefinition,
    )
    .map((task) => ({
      taskArn: task.taskArn,
      privateIp: findPrivateIp(task),
    }));

  if (targets.length === 0) {
    throw new Error("No se encontraron tasks RUNNING de la revision objetivo");
  }

  if (targets.some((target) => !target.privateIp)) {
    throw new Error("ECS no devolvio la IP privada de una task objetivo");
  }

  return targets;
}

function findPrivateIp(task) {
  const containerIp = task.containers
    ?.flatMap((container) => container.networkInterfaces ?? [])
    .find((networkInterface) => networkInterface.privateIpv4Address)
    ?.privateIpv4Address;

  if (containerIp) {
    return containerIp;
  }

  return task.attachments
    ?.flatMap((attachment) => attachment.details ?? [])
    .find((detail) => detail.name === "privateIPv4Address")
    ?.value;
}

function buildChecks(privateIp, config) {
  const baseUrl = `http://${privateIp}:${config.port}`;

  return [
    {
      url: `${baseUrl}${config.healthPath}`,
      expectedStatus: 200,
      expectedBody: config.expectedBody,
      timeoutMs: config.timeoutMs,
    },
    ...config.smokePaths.map((path) => ({
      url: `${baseUrl}${path}`,
      expectedStatus: 200,
      expectedBody: null,
      timeoutMs: config.timeoutMs,
    })),
  ];
}

async function publishFailureAlert({
  snsClient,
  alertTopicArn,
  event,
  attempt,
  failure,
  logger,
}) {
  if (!alertTopicArn) {
    logger.error("ALERT_TOPIC_ARN is not configured; skipping SNS alert");
    return;
  }

  try {
    await snsClient.send(
      new PublishCommand({
        TopicArn: alertTopicArn,
        Subject: "ECS deployment rejected by validation hook",
        Message: JSON.stringify(
          {
            executionId: event?.executionId,
            lifecycleStage: event?.lifecycleStage,
            serviceArn: event?.executionDetails?.serviceArn,
            targetServiceRevisionArn:
              event?.executionDetails?.targetServiceRevisionArn,
            attempts: attempt,
            error: failure,
          },
          null,
          2,
        ),
      }),
    );
  } catch (alertError) {
    // La falla de notificacion nunca debe impedir el rollback.
    logger.error(JSON.stringify({
      message: "Could not publish deployment failure to SNS",
      error: serializeError(alertError),
    }));
  }
}

function serializeError(error) {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      ...(error.details ? { details: error.details } : {}),
    };
  }

  return { name: "Error", message: String(error) };
}
