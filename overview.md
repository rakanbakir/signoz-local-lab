---
name: Overview
description: Top-level entry point for the signoz-local-lab workspace — single-node SigNoz observability lab on Kind.
tags: [overview, index]
---

# signoz-local-lab Overview

Single-node SigNoz observability lab on Kind (Kubernetes-in-Docker). Includes a Python Flask demo app with manual OpenTelemetry instrumentation (traces, metrics, logs), hostmetrics collection, infrastructure monitoring, and pre-built dashboards. Designed for learning observability on a laptop.

## Project

- [README](./README.md) — full project documentation, quick-start, architecture diagram, and component inventory
- [TODO](./TODO.md) — open issues and completed work tracker

## Specifications

OpenSpec specs describe system requirements across four capabilities:

- [cluster-setup](./openspec/specs/cluster-setup/spec.md) — Kind cluster provisioning, nginx ingress, DNS, prerequisite validation
- [otel-pipeline](./openspec/specs/otel-pipeline/spec.md) — OTel Collector DaemonSet, log collection, kubelet metrics, OTLP reception, RBAC, auto-instrumentation
- [signoz-platform](./openspec/specs/signoz-platform/spec.md) — SigNoz Helm deployment, ClickHouse, alertmanager, ingress
- [demo-apps](./openspec/specs/demo-apps/spec.md) — basic-demo Flask app, trace demo generator

## Archived Changes

Completed OpenSpec changes with proposal, design, tasks, and delta specs:

### fix-boutique-instrumentation
Added dotnet/ruby auto-instrumentation to Instrumentation CR; removed non-functional Go annotations (eBPF unavailable on macOS Kind).

- [proposal](./openspec/changes/archive/2026-06-07-fix-boutique-instrumentation/proposal.md)
- [design](./openspec/changes/archive/2026-06-07-fix-boutique-instrumentation/design.md)
- [tasks](./openspec/changes/archive/2026-06-07-fix-boutique-instrumentation/tasks.md)
- [delta spec: otel-pipeline](./openspec/changes/archive/2026-06-07-fix-boutique-instrumentation/specs/otel-pipeline/spec.md)

### replace-hotrod-basic-demo
Replaced HotROD (Jaeger demo) with a lightweight Python Flask app for learning manual OTel SDK instrumentation.

- [proposal](./openspec/changes/archive/2026-06-08-replace-hotrod-basic-demo/proposal.md)
- [design](./openspec/changes/archive/2026-06-08-replace-hotrod-basic-demo/design.md)
- [tasks](./openspec/changes/archive/2026-06-08-replace-hotrod-basic-demo/tasks.md)
- [delta spec: demo-apps](./openspec/changes/archive/2026-06-08-replace-hotrod-basic-demo/specs/demo-apps/spec.md)
