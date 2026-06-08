# cluster-setup Specification

## Purpose
Provision a local Kind (Kubernetes-in-Docker) cluster with nginx ingress and DNS resolution for the SigNoz observability environment.

## Requirements

### Requirement: Kind cluster provisioning
The system SHALL create a single-node Kind cluster named "signoz" that exposes ports 80 and 443 to the host.

#### Scenario: Cluster creation
- **GIVEN** kind, kubectl, helm, and docker are installed
- **WHEN** the setup script runs
- **THEN** a Kind cluster named "signoz" SHALL be created using kind-config.yaml
- **AND** the control-plane node SHALL be labeled ingress-ready=true
- **AND** host ports 80 and 443 SHALL be mapped to container ports 80 and 443

#### Scenario: Recreating existing cluster
- **GIVEN** a Kind cluster named "signoz" already exists
- **WHEN** the setup script runs
- **THEN** the existing cluster SHALL be deleted and recreated

### Requirement: Nginx ingress controller
The system SHALL deploy nginx-ingress in hostNetwork mode as a DaemonSet.

#### Scenario: Ingress controller deployment
- **GIVEN** the Kind cluster is running
- **WHEN** the nginx-ingress Helm chart is installed
- **THEN** the controller SHALL run in hostNetwork mode as a DaemonSet
- **AND** the service SHALL be disabled (controller.daemonset.useHostPort=true)
- **AND** metrics, admission webhooks, and termination grace period SHALL be minimized

### Requirement: Local DNS resolution
The system SHALL configure /etc/hosts to resolve signoz.local to the ingress controller's IP.

#### Scenario: Hosts file configuration
- **GIVEN** the ingress controller has a load balancer IP
- **WHEN** the DNS setup step runs
- **THEN** signoz.local SHALL resolve to the ingress controller IP in /etc/hosts

#### Scenario: Fallback to localhost
- **GIVEN** no load balancer IP is available after 30 retries
- **WHEN** DNS configuration runs
- **THEN** signoz.local SHALL resolve to 127.0.0.1

### Requirement: Prerequisite validation
The system SHALL verify all required CLI tools are installed before proceeding.

#### Scenario: Missing prerequisite
- **GIVEN** a required tool (kind, kubectl, helm, or docker) is missing
- **WHEN** the setup script runs
- **THEN** the script SHALL exit immediately with an error message
