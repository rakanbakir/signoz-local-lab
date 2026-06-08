# demo-apps Specification

## Purpose
Deploy demo applications that generate traces, metrics, and logs for testing and demonstrating the SigNoz observability platform.

## Requirements

### Requirement: Basic trace demo application
The system SHALL deploy a lightweight Python Flask application with manual OTel instrumentation as the primary trace demo.

#### Scenario: Basic demo deployment
- **GIVEN** the SigNoz platform is running
- **WHEN** basic-demo/deploy.yaml is applied
- **THEN** a Deployment named basic-demo SHALL run in the "demo" namespace
- **AND** the app code SHALL be provided via ConfigMap (not a pre-built image)
- **AND** it SHALL use the python:3.11-slim base image with Flask and OTel SDK installed at startup
- **AND** it SHALL be allocated 50m-200m CPU and 64Mi-128Mi memory

#### Scenario: Span generation
- **GIVEN** the basic-demo deployment is running
- **WHEN** any HTTP endpoint is called
- **THEN** the app SHALL create OTel spans for each request
- **AND** parent-child span relationships SHALL be maintained for multi-step operations
- **AND** spans SHALL include relevant attributes (http.method, http.url, custom attributes)

#### Scenario: OTLP export
- **GIVEN** OTel spans are created
- **WHEN** spans are completed
- **THEN** they SHALL be exported via OTLP gRPC to the SigNoz collector at my-release-signoz-otel-collector.platform.svc.cluster.local:4317
- **AND** export SHALL use insecure mode (no TLS within the cluster)

#### Scenario: Basic demo access
- **GIVEN** the basic-demo deployment is ready
- **WHEN** port-forward is established from localhost:8080 to the service port 8080
- **THEN** the demo SHALL be accessible at http://localhost:8080
- **AND** the root path (/) SHALL return a greeting
- **AND** /api/users SHALL return a list of users with nested spans
- **AND** /api/users/<id> SHALL return a single user with simulated DB/cache spans

### Requirement: Online Boutique demo application
The system SHALL deploy Google's Online Boutique microservices demo application.

#### Scenario: Online Boutique deployment
- **GIVEN** the SigNoz platform is running
- **WHEN** online-boutique.yaml is applied
- **THEN** the full microservices demo SHALL be deployed
- **AND** each service SHALL export OTLP telemetry to the SigNoz collector

### Requirement: Trace demo application
The system SHALL deploy a custom trace demo for generating sample traces.

#### Scenario: Trace demo deployment
- **GIVEN** the SigNoz platform is running
- **WHEN** trace-demo.yaml is applied
- **THEN** the trace demo application SHALL be deployed
- **AND** it SHALL generate sample traces visible in SigNoz
