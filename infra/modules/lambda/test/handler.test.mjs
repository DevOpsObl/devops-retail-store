import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { createServer } from "node:http";

import {
  DescribeServiceRevisionsCommand,
  DescribeTasksCommand,
  ListTasksCommand,
} from "@aws-sdk/client-ecs";
import { PublishCommand } from "@aws-sdk/client-sns";

import { createHandler } from "../src/handler.mjs";

let server;
let port;

before(async () => {
  server = createServer((request, response) => {
    if (request.url === "/health") {
      response.writeHead(200, { "Content-Type": "text/plain" });
      response.end("OK");
      return;
    }

    if (request.url === "/catalog/size") {
      response.writeHead(200, { "Content-Type": "application/json" });
      response.end('{"size":1}');
      return;
    }

    response.writeHead(404);
    response.end();
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });

  const address = server.address();
  port = address.port;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

describe("ECS deployment hook handler", () => {
  it("aprueba la revision objetivo cuando health y smoke checks pasan", async () => {
    const published = [];
    const handler = createHandler({
      ecsClient: fakeEcsClient(),
      snsClient: fakeSnsClient(published),
      logger: silentLogger,
      alertTopicArn: "arn:aws:sns:us-east-1:123456789012:deployments",
    });

    const result = await handler(
      eventWith({ smokePaths: ["/catalog/size"] }),
    );

    assert.equal(result.hookStatus, "SUCCEEDED");
    assert.match(result.reason, /2 checks passed/);
    assert.equal(published.length, 0);
  });

  it("devuelve IN_PROGRESS y conserva el intento mientras quedan reintentos", async () => {
    const handler = createHandler({
      ecsClient: fakeEcsClient(),
      snsClient: fakeSnsClient([]),
      logger: silentLogger,
    });

    const result = await handler(
      eventWith({ expectedBody: "BROKEN", maxAttempts: 3, attempt: 1 }),
    );

    assert.equal(result.hookStatus, "IN_PROGRESS");
    assert.equal(result.callBackDelay, 30);
    assert.deepEqual(result.hookDetails, { attempt: 2 });
  });

  it("publica en SNS y devuelve FAILED al agotar los intentos", async () => {
    const published = [];
    const handler = createHandler({
      ecsClient: fakeEcsClient(),
      snsClient: fakeSnsClient(published),
      logger: silentLogger,
      alertTopicArn: "arn:aws:sns:us-east-1:123456789012:deployments",
    });

    const result = await handler(
      eventWith({ expectedBody: "BROKEN", maxAttempts: 3, attempt: 3 }),
    );

    assert.equal(result.hookStatus, "FAILED");
    assert.match(result.reason, /after 3 attempt/);
    assert.equal(published.length, 1);
    assert.match(published[0].Message, /targetServiceRevisionArn/);
  });

  it("no confunde tasks de la revision anterior con la nueva", async () => {
    const handler = createHandler({
      ecsClient: fakeEcsClient({ onlyOldRevision: true }),
      snsClient: fakeSnsClient([]),
      logger: silentLogger,
    });

    const result = await handler(eventWith({ maxAttempts: 2, attempt: 1 }));

    assert.equal(result.hookStatus, "IN_PROGRESS");
    assert.match(result.reason, /revision objetivo/);
  });
});

function eventWith(overrides = {}) {
  return {
    executionId: "execution-123",
    lifecycleStage: "POST_SCALE_UP",
    resourceArn:
      "arn:aws:ecs:us-east-1:123456789012:service-deployment/cluster/catalog/deployment",
    executionDetails: {
      serviceArn:
        "arn:aws:ecs:us-east-1:123456789012:service/cluster/catalog",
      targetServiceRevisionArn:
        "arn:aws:ecs:us-east-1:123456789012:service-revision/cluster/catalog/2",
      testTrafficWeights: {},
      productionTrafficWeights: {},
    },
    hookDetails: {
      port,
      healthPath: "/health",
      expectedBody: "OK",
      smokePaths: [],
      maxAttempts: 3,
      callbackDelay: 30,
      timeoutMs: 500,
      ...overrides,
    },
  };
}

function fakeEcsClient({ onlyOldRevision = false } = {}) {
  const targetTaskDefinition =
    "arn:aws:ecs:us-east-1:123456789012:task-definition/catalog:2";

  return {
    async send(command) {
      if (command instanceof DescribeServiceRevisionsCommand) {
        return {
          serviceRevisions: [{
            clusterArn:
              "arn:aws:ecs:us-east-1:123456789012:cluster/cluster",
            taskDefinition: targetTaskDefinition,
          }],
        };
      }

      if (command instanceof ListTasksCommand) {
        return { taskArns: ["arn:aws:ecs:task/cluster/task-1"] };
      }

      if (command instanceof DescribeTasksCommand) {
        return {
          tasks: [{
            taskArn: "arn:aws:ecs:task/cluster/task-1",
            lastStatus: "RUNNING",
            taskDefinitionArn: onlyOldRevision
              ? "arn:aws:ecs:us-east-1:123456789012:task-definition/catalog:1"
              : targetTaskDefinition,
            containers: [{
              networkInterfaces: [{ privateIpv4Address: "127.0.0.1" }],
            }],
          }],
        };
      }

      throw new Error(`Unexpected command ${command.constructor.name}`);
    },
  };
}

function fakeSnsClient(published) {
  return {
    async send(command) {
      assert.ok(command instanceof PublishCommand);
      published.push(command.input);
      return { MessageId: "message-1" };
    },
  };
}

const silentLogger = {
  info() {},
  error() {},
};
