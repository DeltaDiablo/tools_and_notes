# Debugging Kubernetes Containers

Troubleshooting containers in Kubernetes pods requires systematic inspection of logs, configurations, and runtime state. Here are the key debugging strategies:

## 1. Pod Inspection

Examine pod details and events for configuration issues:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Review the **Events** section for resource constraints, scheduling failures, or configuration errors.

## 2. Container Logs Analysis

Retrieve container logs to diagnose application issues:

```bash
# Single container pod
kubectl logs <pod-name> -n <namespace>

# Multi-container pod
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Previous container instance (after crash)
kubectl logs --previous <pod-name> -c <container-name> -n <namespace>
```

## 3. Interactive Container Access

Execute commands directly within the container:

```bash
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

Use this for running diagnostic tools like `curl`, `nslookup`, or filesystem inspection.

## 4. Ephemeral Debug Containers

Attach temporary debug containers when the main container lacks tools:

```bash
kubectl debug -it <pod-name> --image=busybox:1.28 --target=<container-name>
```

Ideal for containers built with minimal base images.

## 5. Resource and Health Check Validation

Verify resource quotas and limits:

```bash
kubectl describe ns <namespace>
```

Ensure liveness and readiness probes are properly configured in the pod specification.

## 6. Network Connectivity Testing

- Test network connectivity using `curl` or `nslookup` from within containers
- Verify service configurations and network policies
- Check DNS resolution and port accessibility