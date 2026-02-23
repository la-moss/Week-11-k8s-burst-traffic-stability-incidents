# Ticket - SEV-2: API instability under burst traffic

**Customer impact:** intermittent 5xx responses and elevated latency  
**Environment:** prod-like  
**Constraint:** preserve service behavior while restoring stability

## Observations

- Error rate rises during peak request bursts.
- API pod restarts are visible during incidents.
- Worker latency increases before API degradation.
- Deployment throughput is blocked by runtime verification failures.

## Task

Restore runtime health so all verification profiles pass:

- `profile1`
- `profile2`
- `profile3`
- `profile4`
