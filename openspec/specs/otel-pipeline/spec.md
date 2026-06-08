# otel-pipeline Specification

## Purpose
Collect, process, and export telemetry from the Kubernetes cluster to SigNoz using OpenTelemetry Collector, Operator, and auto-instrumentation.

## Requirements

### Requirement: OTel Collector DaemonSet
The system SHALL run an OTel Collector as a DaemonSet (one per node) to collect cluster-wide telemetry.

#### Scenario: Collector deployment
- **GIVEN** the OTel Operator is installed
- **WHEN** the OpenTelemetryCollector CR is applied
- **THEN** a Collector SHALL run on every node in daemonset mode
- **AND** it SHALL use the otel/opentelemetry-collector-contrib:0.111.0 image
- **AND** it SHALL be allocated 50m-100m CPU and 64Mi-128Mi memory

### Requirement: Log collection
The system SHALL collect container logs from /var/log/pods and parse them into structured format.

#### Scenario: Container log parsing
- **GIVEN** the Collector is running on a node
- **WHEN** container logs are written to /var/log/pods
- **THEN** the filelog receiver SHALL detect the log format (Docker JSON, CRI-O, or containerd)
- **AND** SHALL parse timestamps, streams, and log content
- **AND** SHALL recombine multi-line logs into single entries
- **AND** SHALL extract Kubernetes metadata (namespace, pod name, container name) from the file path

#### Scenario: Service name assignment
- **GIVEN** log entries have Kubernetes metadata attached
- **WHEN** logs are processed by the transform processor
- **THEN** the service.name resource attribute SHALL be set to "k8s/<namespace>/<pod_name>"

### Requirement: Kubelet metrics collection
The system SHALL collect node and pod metrics from the kubelet API.

#### Scenario: Kubeletstats receiver
- **GIVEN** the Collector has a ServiceAccount with node access
- **WHEN** the kubeletstats receiver runs
- **THEN** node and pod metrics SHALL be collected every 30 seconds
- **AND** the kubelet endpoint SHALL be resolved via KUBE_NODE_NAME environment variable

### Requirement: OTLP reception
The system SHALL accept OTLP telemetry (traces, metrics) from instrumented applications.

#### Scenario: OTLP endpoint
- **GIVEN** the Collector DaemonSet is running
- **WHEN** applications send OTLP data
- **THEN** the Collector SHALL accept data via gRPC on port 4317 and HTTP on port 4318

### Requirement: Kubernetes metadata enrichment
The system SHALL enrich all telemetry with Kubernetes metadata.

#### Scenario: Metadata attachment
- **GIVEN** the Collector is processing telemetry
- **WHEN** the k8sattributes processor runs
- **THEN** namespace, pod name, and node name SHALL be attached as resource attributes
- **AND** passthrough SHALL be disabled to prevent duplicate attributes

### Requirement: Export to SigNoz
The system SHALL export all collected telemetry to the SigNoz OTel Collector service.

#### Scenario: OTLP HTTP export
- **GIVEN** telemetry is processed
- **WHEN** the exporter pipeline runs
- **THEN** data SHALL be sent via OTLP HTTP to http://my-release-signoz-otel-collector.platform.svc.cluster.local:4318
- **AND** TLS SHALL be disabled (insecure: true) for internal cluster communication

### Requirement: Memory limiting
The system SHALL limit Collector memory usage to prevent node resource exhaustion.

#### Scenario: Memory limiter
- **GIVEN** the Collector is processing telemetry
- **WHEN** memory usage exceeds 64Mi
- **THEN** the memory limiter processor SHALL trigger backpressure or data dropping
- **AND** spike_limit_mib SHALL be 16Mi

### Requirement: RBAC permissions
The system SHALL grant the Collector ServiceAccount read access to pods, nodes, node stats, and namespaces.

#### Scenario: ClusterRole bindings
- **GIVEN** the k8s-collector ServiceAccount is created
- **WHEN** the ClusterRole and ClusterRoleBinding are applied
- **THEN** the Collector SHALL have get, list, and watch permissions on pods, nodes, nodes/stats, and namespaces

### Requirement: Auto-instrumentation
The system SHALL provide an Instrumentation CR for auto-instrumenting applications.

#### Scenario: Instrumentation configuration
- **GIVEN** the OTel Operator is installed
- **WHEN** the Instrumentation CR is applied
- **THEN** auto-instrumentation SHALL be available for Python, Java, Node.js, .NET, and Ruby applications
- **AND** telemetry SHALL be exported to http://my-release-signoz-otel-collector.platform.svc.cluster.local:4318
- **AND** tracecontext, baggage, and b3 propagation SHALL be supported
- **AND** sampling SHALL be parentbased_traceidratio at 100% (argument: "1")

### Requirement: Go instrumentation limitation
The system SHALL NOT use OTel Operator auto-instrumentation for Go applications.

#### Scenario: Go applications rely on compiled SDK
- **GIVEN** a Go application is deployed in the cluster
- **WHEN** the Instrumentation CR is applied
- **THEN** the system SHALL NOT provide auto-instrumentation for Go via the Operator
- **AND** Go applications SHALL include the OTel SDK at compile time to export telemetry
