# Timeline (simulated)

- T+00m: rollout begins in prod-like namespace
- T+06m: API error rate increases under burst traffic
- T+10m: restart count rises on API pods
- T+14m: worker latency increases and request queueing appears
- T+19m: partial fixes reduce errors but latency remains elevated
- T+26m: runtime verification still failing on one or more SLO checks
