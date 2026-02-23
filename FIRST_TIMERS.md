# First-Timer Setup (Kind + kubectl)

## Install tools

Required:

- Docker Desktop
- kind
- kubectl
- curl

On macOS with Homebrew:

```bash
brew install kind kubectl
```

Check tools:

```bash
docker --version
kind version
kubectl version --client
curl --version
```

## Start Docker

Kind uses Docker containers as cluster nodes.
Start Docker Desktop before creating a cluster.

## Create cluster

From this repo root:

```bash
kind create cluster --name week1-k8s --config kind/kind-config.yaml
kubectl cluster-info
kubectl get nodes
```

## Deploy a challenge

```bash
kubectl apply -k manifests/overlays/challenge1
kubectl -n incident-lab rollout status deploy/worker --timeout=180s
kubectl -n incident-lab rollout status deploy/api --timeout=180s
```

## Run verification

```bash
VERIFY_PROFILE=profile1 bash scripts/verify/verify.sh
```

## Reset and cleanup

Reset workload:

```bash
kubectl delete ns incident-lab --wait=true
kubectl apply -k manifests/overlays/challenge1
```

Delete cluster:

```bash
kind delete cluster --name week1-k8s
```
