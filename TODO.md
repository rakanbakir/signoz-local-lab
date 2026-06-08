# TODO

## Logs

### Parsing needs fixing for filters to work

Container logs from the filelog receiver are ingested raw (containerd format). The log body contains the full timestamp + stream prefix like:

```
2026-06-08T03:05:19.494220305Z stderr F 127.0.0.1 - - [08/Jun/2026 03:05:19] "GET /api/users HTTP/1.1" 200 -
```

SigNoz log filters (e.g., filter by `GET` or status code) don't match because the parser operators in `otel-collector-daemonset.yaml` may not correctly extract the structured fields (`time`, `stream`, `logtag`, `log`).

- [ ] Verify containerd/CRO/Docker log format detection in filelog operators
- [ ] Ensure `extract_metadata_from_filepath` regex matches all kubernetes pod log paths with `/hostfs` prefix
- [ ] Add `timestamp` extraction so SigNoz shows correct log timestamps (not collector receipt time)
- [ ] Test filter queries in SigNoz Logs tab (e.g., `body contains GET`, `namespace = demo`)

---

## Completed

- [x] SigNoz platform deployed on Kind
- [x] OTel Collector DaemonSet (k8s-collector) with traces, metrics, logs
- [x] Basic demo app (Python Flask) with manual OTel instrumentation
- [x] Auto-instrumentation CR for .NET and Ruby (Go limitation documented)
- [x] Dashboards: Basic Demo Overview, Basic Demo HTTP Metrics, APM Metrics, Host Metrics, ClickHouse
- [x] Infrastructure monitoring (host.name label via resourcedetection + resource processors)
- [x] Host metrics (CPU, memory, disk, network) via hostmetrics receiver
- [x] OTel metrics export from demo app (Flask HTTP metrics)
- [x] OTel logging from demo app (structured logs via OTLP)
- [x] Container log collection via filelog receiver
