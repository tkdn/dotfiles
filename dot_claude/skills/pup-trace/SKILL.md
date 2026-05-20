---
name: pup-trace
description: >
  Fetch and analyze Datadog APM traces using the `pup` CLI tool.
  Use this skill whenever the user wants to investigate performance issues,
  analyze N+1 queries, inspect slow spans, or understand trace behavior in Datadog —
  even if they don't say "pup" explicitly. Trigger on phrases like "トレース取って",
  "Datadogで確認して", "パフォーマンス分析して", "スパンを見て", "N+1を確認して",
  "fetch the trace", "check the trace", "analyze performance in Datadog",
  "investigate latency", "pull the trace".
---

# pup-trace

Fetch and analyze Datadog APM spans using the `pup` CLI, then surface actionable insights.

## Commands

### Search individual spans
```bash
pup traces search --query "<query>" --from "<time>" --limit <n>
```

### Aggregate statistics
```bash
pup traces aggregate --query "<query>" --compute "<compute>" --group-by "<facet>" --from "<time>"
```

## Query syntax

| Pattern | Meaning |
|---|---|
| `service:web-server` | Filter by service name |
| `env:production` | Filter by environment |
| `@http.status_code:500` | Filter by tag value |
| `@duration:>1000000000` | Filter by duration (nanoseconds) |
| `resource_name:"GET /api"` | Filter by resource name |
| `trace_id:xxxxxxx` | Fetch a specific trace |

**Important: duration values are in nanoseconds** (1 second = 1,000,000,000 ns)

## Key options

| Option | Default | Description |
|---|---|---|
| `--from` | `1h` | Start time (e.g. `30m`, `4h`, `7d`, RFC3339) |
| `--to` | `now` | End time |
| `--limit` | `50` | Number of spans to return (max 1000) |
| `--sort` | `-timestamp` | Sort order (`timestamp` or `-timestamp`) |

## Workflow

### 1. Build the query

Construct a query from what the user tells you — service name, environment, span name, time window, etc.
If the information is ambiguous, ask before running.

### 2. Start small

Begin with `--limit 10` or `--limit 20`. Refine the query if too many irrelevant spans come back.

### 3. Analyze the results

Look for:
- **Repeated spans**: The same operation appearing many times within one request is a sign of N+1
- **Duration outliers**: Spans that are much slower than the rest are bottleneck candidates
- **Error spans**: Look for `status:error` or `@http.status_code:5xx`
- **Span hierarchy**: Parent-child relationships reveal the flow of a request

### 4. Use aggregation to spot trends

Individual spans show detail; aggregation shows patterns:

```bash
# P99 latency by service
pup traces aggregate --query="env:production" \
  --compute="percentile(@duration, 99)" \
  --group-by="service"

# Span count by resource (useful for N+1 detection)
pup traces aggregate --query="service:myapp" \
  --compute="count" \
  --group-by="resource_name"
```

### 5. Suggest next steps

After presenting the analysis, propose what makes sense given the context:
- Code fix suggestions (e.g. resolving an N+1)
- Follow-up queries to dig deeper
- Comparison across services or time windows

Always check with the user before taking action — they may just want the analysis.
