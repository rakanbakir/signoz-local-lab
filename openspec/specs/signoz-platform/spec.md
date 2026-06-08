# signoz-platform Specification

## Purpose
Deploy and configure the SigNoz observability platform (query service, frontend, alertmanager, ClickHouse, and Zookeeper) on a local Kubernetes cluster via Helm.

## Requirements

### Requirement: ClickHouse datastore
The system SHALL deploy ClickHouse as the telemetry datastore with Zookeeper for coordination.

#### Scenario: Default ClickHouse deployment
- **GIVEN** the SigNoz Helm chart is installed
- **WHEN** ClickHouse is enabled in values
- **THEN** a ClickHouse instance SHALL be deployed with 5Gi persistent storage and 200m-1.5 CPU / 768Mi-2Gi memory limits
- **AND** Zookeeper SHALL be deployed with 1Gi persistent storage and 50m-200m CPU / 128Mi-256Mi memory limits

#### Scenario: Memory configuration
- **GIVEN** ClickHouse is deployed in a resource-constrained local cluster
- **WHEN** the pod starts
- **THEN** max_server_memory_usage SHALL be unbounded (0)
- **AND** max_server_memory_usage_to_ram_ratio SHALL be set to 0.85

### Requirement: SigNoz application services
The system SHALL deploy the SigNoz query service and frontend with a single replica.

#### Scenario: Default application deployment
- **GIVEN** the SigNoz Helm chart is installed
- **WHEN** signoz.replicaCount is 1
- **THEN** the query service SHALL be allocated 100m-500m CPU and 256Mi-512Mi memory
- **AND** persistence SHALL be enabled with 500Mi storage

### Requirement: Ingress access
The system SHALL expose the SigNoz frontend via an nginx ingress on signoz.local.

#### Scenario: Ingress configuration
- **GIVEN** the cluster is running with nginx ingress controller
- **WHEN** a request arrives at signoz.local
- **THEN** traffic SHALL be routed to the SigNoz frontend on port 8080
- **AND** the proxy-body-size SHALL be set to 50m

### Requirement: Alertmanager configuration
The system SHALL configure the SigNoz built-in alertmanager.

#### Scenario: Alertmanager provider
- **GIVEN** the SigNoz Helm chart is installed
- **WHEN** signoz_alertmanager_provider is set to "signoz"
- **THEN** alerts SHALL be handled by the built-in SigNoz alertmanager
- **AND** the external URL SHALL be set to http://signoz.local

### Requirement: Telemetry store provider
The system SHALL use ClickHouse as the telemetry storage backend.

#### Scenario: Telemetry store configuration
- **GIVEN** the SigNoz Helm chart is installed
- **WHEN** signoz_telemetrystore_provider is set to "clickhouse"
- **THEN** all telemetry data (traces, metrics, logs) SHALL be stored in ClickHouse

### Requirement: Telemetry store migration
The system SHALL run a telemetry store migrator on deploy.

#### Scenario: Migrator enabled
- **GIVEN** the SigNoz Helm chart is installed
- **WHEN** telemetryStoreMigrator.enabled is true
- **THEN** a migration job SHALL run with 50m-200m CPU and 64Mi-128Mi memory limits
