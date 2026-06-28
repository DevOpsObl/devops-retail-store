import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { createServer } from "node:http";

import {
  checkHealth,
  HealthCheckError,
} from "../src/health-check.mjs";

let server;
let baseUrl;

before(async () => {
  server = createServer((request, response) => {
    switch (request.url) {
      case "/health":
        response.writeHead(200, {
          "Content-Type": "text/plain",
        });
        response.end("OK");
        break;

      case "/wrong-body":
        response.writeHead(200, {
          "Content-Type": "text/plain",
        });
        response.end("NOT_OK");
        break;

      case "/unavailable":
        response.writeHead(503, {
          "Content-Type": "text/plain",
        });
        response.end("Service Unavailable");
        break;

      case "/slow":
        setTimeout(() => {
          if (!response.destroyed) {
            response.writeHead(200, {
              "Content-Type": "text/plain",
            });
            response.end("OK");
          }
        }, 200);
        break;

      default:
        response.writeHead(404);
        response.end();
    }
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);

    server.listen(0, "127.0.0.1", () => {
      resolve();
    });
  });

  const address = server.address();

  if (!address || typeof address === "string") {
    throw new Error(
      "No fue posible obtener el puerto del servidor local",
    );
  }

  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
});

describe("checkHealth", () => {
  it("acepta un endpoint saludable", async () => {
    const result = await checkHealth({
      url: `${baseUrl}/health`,
      expectedStatus: 200,
      expectedBody: "OK",
      timeoutMs: 1000,
    });

    assert.equal(result.ok, true);
    assert.equal(result.status, 200);
    assert.equal(result.url, `${baseUrl}/health`);
    assert.equal(typeof result.latencyMs, "number");
  });

  it("rechaza un código HTTP inesperado", async () => {
    await assert.rejects(
      () =>
        checkHealth({
          url: `${baseUrl}/unavailable`,
          expectedStatus: 200,
          expectedBody: "OK",
          timeoutMs: 1000,
        }),
      (error) => {
        assert.ok(error instanceof HealthCheckError);
        assert.equal(error.details.status, 503);
        assert.equal(error.details.expectedStatus, 200);
        return true;
      },
    );
  });

  it("rechaza un body inesperado", async () => {
    await assert.rejects(
      () =>
        checkHealth({
          url: `${baseUrl}/wrong-body`,
          expectedStatus: 200,
          expectedBody: "OK",
          timeoutMs: 1000,
        }),
      (error) => {
        assert.ok(error instanceof HealthCheckError);
        assert.equal(error.details.receivedBody, "NOT_OK");
        return true;
      },
    );
  });

  it("rechaza un endpoint que supera el timeout", async () => {
    await assert.rejects(
      () =>
        checkHealth({
          url: `${baseUrl}/slow`,
          expectedStatus: 200,
          expectedBody: "OK",
          timeoutMs: 30,
        }),
      (error) => {
        assert.ok(error instanceof HealthCheckError);
        assert.match(
          error.message,
          /no respondió dentro de 30 ms/,
        );
        return true;
      },
    );
  });

  it("rechaza protocolos distintos de HTTP y HTTPS", async () => {
    await assert.rejects(
      () =>
        checkHealth({
          url: "file:///etc/passwd",
        }),
      {
        name: "TypeError",
        message:
          "El health check solamente admite protocolos HTTP o HTTPS",
      },
    );
  });
});