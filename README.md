# Week 1 - Kubernetes Incident Lab (Runtime-Only)

This lab simulates a production incident set around resource governance and service stability.

You investigate using live runtime signals and fix manifests until verification passes.

## Start Here

Before you begin, read:

- `incident/ticket.md` - current incident statement, constraints, and success criteria.
- `incident/timeline.md` - event chronology and symptom progression during the outage.

## Objective

Complete all four challenge profiles:

- `profile1` (core incident)
- `profile2` (related incident A)
- `profile3` (related incident B)
- `profile4` (related incident C)

## Prerequisites

- Docker
- kind
- kubectl
- curl
- bash

## Repository Layout

```text
incident/                    # ticket + timeline context
kind/                        # local cluster configuration
manifests/
  base/                      # shared workloads and services
  overlays/
    dev/
    prod/
    challenge1/
    challenge2/
    challenge3/
    challenge4/
scripts/
  verify/                    # runtime verification
hints/                       # optional assistance (not required)
solutions/                   # optional full solutions
```

## Setup

1) Create cluster:

```bash
kind create cluster --name week1-k8s --config kind/kind-config.yaml
```

2) Deploy challenge 1:

```bash
kubectl apply -k manifests/overlays/challenge1
kubectl -n incident-lab rollout status deploy/worker --timeout=180s
kubectl -n incident-lab rollout status deploy/api --timeout=180s
```

3) Verify challenge 1:

```bash
VERIFY_PROFILE=profile1 bash scripts/verify/verify.sh
```

## Standard Workflow

For each challenge:

```bash
kubectl apply -k manifests/overlays/challengeX
kubectl -n incident-lab rollout status deploy/worker --timeout=180s
kubectl -n incident-lab rollout status deploy/api --timeout=180s
VERIFY_PROFILE=profileX bash scripts/verify/verify.sh
```

Where `X` is `1`, `2`, `3`, or `4`.

## Common Runtime Commands

```bash
kubectl -n incident-lab get pods
kubectl -n incident-lab get svc
kubectl -n incident-lab get events --sort-by=.lastTimestamp
kubectl -n incident-lab logs deploy/api --tail=200
kubectl -n incident-lab logs deploy/worker --tail=200
kubectl -n incident-lab describe deploy/api
kubectl -n incident-lab describe deploy/worker
```

## Validation

Run all profiles:

```bash
VERIFY_PROFILE=profile1 bash scripts/verify/verify.sh
VERIFY_PROFILE=profile2 bash scripts/verify/verify.sh
VERIFY_PROFILE=profile3 bash scripts/verify/verify.sh
VERIFY_PROFILE=profile4 bash scripts/verify/verify.sh
```

## Cleanup

```bash
kind delete cluster --name week1-k8s
```
