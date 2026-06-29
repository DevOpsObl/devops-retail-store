/**
 * Error controlado producido por una validación de salud.
 */
export class HealthCheckError extends Error {
  /**
   * @param {string} message
   * @param {Record<string, unknown>} details
   */
  constructor(message, details = {}) {
    super(message);
    this.name = "HealthCheckError";
    this.details = details;
  }
}

/**
 * Valida la disponibilidad y respuesta de un endpoint HTTP.
 *
 * La dependencia fetch se puede reemplazar durante las pruebas.
 *
 * @param {object} options
 * @param {string} options.url
 * @param {number} [options.expectedStatus=200]
 * @param {string|null} [options.expectedBody="OK"]
 * @param {number} [options.timeoutMs=2000]
 * @param {typeof fetch} [options.fetchImpl=fetch]
 *
 * @returns {Promise<{
 *   ok: true,
 *   url: string,
 *   status: number,
 *   latencyMs: number
 * }>}
 */
export async function checkHealth({
  url,
  expectedStatus = 200,
  expectedBody = "OK",
  timeoutMs = 2000,
  fetchImpl = fetch,
}) {
  validateOptions({
    url,
    expectedStatus,
    expectedBody,
    timeoutMs,
    fetchImpl,
  });

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  const startedAt = performance.now();

  try {
    const response = await fetchImpl(url, {
      method: "GET",
      headers: {
        Accept: "text/plain, application/json",
        "User-Agent": "retailstore-deployment-validator/0.1",
      },
      redirect: "error",
      signal: controller.signal,
    });

    const body = (await response.text()).trim();
    const latencyMs = Math.round(performance.now() - startedAt);

    if (response.status !== expectedStatus) {
      throw new HealthCheckError(
        `El endpoint respondió HTTP ${response.status}; se esperaba ${expectedStatus}`,
        {
          url,
          status: response.status,
          expectedStatus,
          latencyMs,
        },
      );
    }

    if (expectedBody !== null && body !== expectedBody) {
      throw new HealthCheckError(
        "El endpoint respondió un contenido inesperado",
        {
          url,
          status: response.status,
          expectedBody,
          receivedBody: body.slice(0, 200),
          latencyMs,
        },
      );
    }

    return {
      ok: true,
      url,
      status: response.status,
      latencyMs,
    };
  } catch (error) {
    if (error instanceof HealthCheckError) {
      throw error;
    }

    if (error instanceof Error && error.name === "AbortError") {
      throw new HealthCheckError(
        `El endpoint no respondió dentro de ${timeoutMs} ms`,
        {
          url,
          timeoutMs,
        },
      );
    }

    throw new HealthCheckError(
      "No fue posible conectarse con el endpoint",
      {
        url,
        cause: error instanceof Error ? error.message : String(error),
      },
    );
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Valida la configuración antes de realizar conexiones.
 *
 * @param {object} options
 */
function validateOptions({
  url,
  expectedStatus,
  expectedBody,
  timeoutMs,
  fetchImpl,
}) {
  if (typeof url !== "string" || url.trim() === "") {
    throw new TypeError("url debe ser un string no vacío");
  }

  let parsedUrl;

  try {
    parsedUrl = new URL(url);
  } catch {
    throw new TypeError("url debe contener una URL válida");
  }

  if (!["http:", "https:"].includes(parsedUrl.protocol)) {
    throw new TypeError(
      "El health check solamente admite protocolos HTTP o HTTPS",
    );
  }

  if (
    !Number.isInteger(expectedStatus) ||
    expectedStatus < 100 ||
    expectedStatus > 599
  ) {
    throw new TypeError(
      "expectedStatus debe ser un código HTTP válido",
    );
  }

  if (expectedBody !== null && typeof expectedBody !== "string") {
    throw new TypeError(
      "expectedBody debe ser un string o null",
    );
  }

  if (
    !Number.isInteger(timeoutMs) ||
    timeoutMs < 1 ||
    timeoutMs > 30000
  ) {
    throw new TypeError(
      "timeoutMs debe ser un entero entre 1 y 30000",
    );
  }

  if (typeof fetchImpl !== "function") {
    throw new TypeError("fetchImpl debe ser una función");
  }
}