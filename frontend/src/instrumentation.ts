import { trace } from '@opentelemetry/api';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { BasicTracerProvider, BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { SEMRESATTRS_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

export function register() {
  const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;

  if (!otlpEndpoint) {
    console.log('[OTEL] No OTEL_EXPORTER_OTLP_ENDPOINT configured, skipping instrumentation');
    return; // Skip OTEL if no endpoint configured (non-Aspire dev)
  }

  console.log('[OTEL] Initializing OpenTelemetry with endpoint:', otlpEndpoint);

  const resource = new Resource({
    [SEMRESATTRS_SERVICE_NAME]: 'frontend',
  });

  const provider = new BasicTracerProvider({
    resource,
  });

  const exporter = new OTLPTraceExporter({
    url: otlpEndpoint,
  });

  provider.addSpanProcessor(new BatchSpanProcessor(exporter));
  provider.register();

  console.log('[OTEL] OpenTelemetry initialized successfully');
}
