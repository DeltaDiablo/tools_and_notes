# Kubernetes Commands Reference

A comprehensive guide to commonly used Kubernetes (kubectl) commands.

## Table of Contents
- [Cluster Information](#cluster-information)
- [Contexts and Configuration](#contexts-and-configuration)
- [Pods](#pods)
- [Deployments](#deployments)
- [Services](#services)
- [Namespaces](#namespaces)
- [ConfigMaps and Secrets](#configmaps-and-secrets)
- [Logs and Debugging](#logs-and-debugging)
- [Resource Management](#resource-management)
- [Networking](#networking)
- [Storage](#storage)
- [RBAC and Security](#rbac-and-security)
- [Scaling and Updates](#scaling-and-updates)

## Cluster Information

```bash
# Get cluster information
kubectl cluster-info

# View cluster nodes
kubectl get nodes

# View node details
kubectl describe node <node-name>

# Get cluster version
kubectl version

# Get cluster API resources
kubectl api-resources
```

## Contexts and Configuration

```bash
# View current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Set default namespace for context
kubectl config set-context --current --namespace=<namespace>

# View kubeconfig
kubectl config view
```

## Pods

```bash
# List all pods in current namespace
kubectl get pods

# List all pods in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# List pods with more details
kubectl get pods -o wide

# Describe a pod
kubectl describe pod <pod-name>

# Get pod YAML
kubectl get pod <pod-name> -o yaml

# Create a pod from YAML
kubectl apply -f pod.yaml

# Delete a pod
kubectl delete pod <pod-name>

# Execute command in a pod
kubectl exec <pod-name> -- <command>

# Interactive shell in a pod
kubectl exec -it <pod-name> -- /bin/bash

# Execute command in specific container
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Port forwarding
kubectl port-forward <pod-name> <local-port>:<pod-port>

# Copy files to/from pod
kubectl cp <pod-name>:/path/to/file /local/path
kubectl cp /local/path <pod-name>:/path/to/file
```

## Deployments

```bash
# List deployments
kubectl get deployments

# Describe a deployment
kubectl describe deployment <deployment-name>

# Create deployment
kubectl create deployment <name> --image=<image>

# Apply deployment from file
kubectl apply -f deployment.yaml

# Delete deployment
kubectl delete deployment <deployment-name>

# Edit deployment
kubectl edit deployment <deployment-name>

# Update deployment image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>

# Rollout status
kubectl rollout status deployment/<deployment-name>

# Rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback deployment
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision-number>
```

## Services

```bash
# List services
kubectl get services
kubectl get svc

# Describe a service
kubectl describe service <service-name>

# Create service
kubectl expose deployment <deployment-name> --port=<port> --type=<type>

# Delete service
kubectl delete service <service-name>

# Get service endpoints
kubectl get endpoints <service-name>

# Edit service
kubectl edit service <service-name>
```

## Namespaces

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace <namespace-name>

# Delete namespace
kubectl delete namespace <namespace-name>

# Describe namespace
kubectl describe namespace <namespace-name>

# Get resources in specific namespace
kubectl get pods -n <namespace-name>
```

## ConfigMaps and Secrets

```bash
# List ConfigMaps
kubectl get configmaps
kubectl get cm

# Create ConfigMap from literal
kubectl create configmap <name> --from-literal=<key>=<value>

# Create ConfigMap from file
kubectl create configmap <name> --from-file=<file-path>

# Describe ConfigMap
kubectl describe configmap <name>

# List Secrets
kubectl get secrets

# Create Secret from literal
kubectl create secret generic <name> --from-literal=<key>=<value>

# Create Secret from file
kubectl create secret generic <name> --from-file=<file-path>

# Describe Secret
kubectl describe secret <name>

# Get Secret data (base64 encoded)
kubectl get secret <name> -o yaml
```

## Logs and Debugging

```bash
# View pod logs
kubectl logs <pod-name>

# View logs from specific container
kubectl logs <pod-name> -c <container-name>

# Follow logs (stream)
kubectl logs -f <pod-name>

# View logs from previous container instance
kubectl logs <pod-name> --previous

# View logs with timestamps
kubectl logs <pod-name> --timestamps

# View last N lines of logs
kubectl logs <pod-name> --tail=<number>

# View logs since time
kubectl logs <pod-name> --since=1h

# View events
kubectl get events

# View events sorted by time
kubectl get events --sort-by='.lastTimestamp'

# Debug with ephemeral container
kubectl debug <pod-name> -it --image=busybox

# Top nodes (resource usage)
kubectl top nodes

# Top pods (resource usage)
kubectl top pods
```

## Resource Management

```bash
# Get all resources
kubectl get all

# Get all resources in namespace
kubectl get all -n <namespace>

# Get multiple resource types
kubectl get pods,services,deployments

# Watch resources (live updates)
kubectl get pods --watch
kubectl get pods -w

# Output in different formats
kubectl get pods -o json
kubectl get pods -o yaml
kubectl get pods -o wide
kubectl get pods -o name

# Filter with labels
kubectl get pods -l <label-key>=<label-value>

# Filter with field selectors
kubectl get pods --field-selector status.phase=Running

# Show labels
kubectl get pods --show-labels

# Delete resources by label
kubectl delete pods -l <label-key>=<label-value>

# Delete all pods in namespace
kubectl delete pods --all -n <namespace>
```

## Networking

```bash
# List ingresses
kubectl get ingress

# Describe ingress
kubectl describe ingress <ingress-name>

# List network policies
kubectl get networkpolicies

# Describe network policy
kubectl describe networkpolicy <policy-name>

# Test connectivity from pod
kubectl exec <pod-name> -- ping <target>
kubectl exec <pod-name> -- curl <url>

# DNS debugging
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>
```

## Storage

```bash
# List persistent volumes
kubectl get pv

# List persistent volume claims
kubectl get pvc

# Describe PVC
kubectl describe pvc <pvc-name>

# List storage classes
kubectl get storageclass
kubectl get sc

# Describe storage class
kubectl describe storageclass <storage-class-name>
```

## RBAC and Security

```bash
# List service accounts
kubectl get serviceaccounts
kubectl get sa

# List roles
kubectl get roles

# List cluster roles
kubectl get clusterroles

# List role bindings
kubectl get rolebindings

# List cluster role bindings
kubectl get clusterrolebindings

# Check if you can perform action
kubectl auth can-i <verb> <resource>
kubectl auth can-i create deployments

# Check permissions for service account
kubectl auth can-i create deployments --as=system:serviceaccount:<namespace>:<sa-name>

# Create role
kubectl create role <role-name> --verb=<verbs> --resource=<resources>

# Create role binding
kubectl create rolebinding <binding-name> --role=<role-name> --user=<user-name>
```

## Scaling and Updates

```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=<number>

# Autoscale deployment
kubectl autoscale deployment <deployment-name> --min=<min> --max=<max> --cpu-percent=<percent>

# List horizontal pod autoscalers
kubectl get hpa

# Patch resource
kubectl patch deployment <deployment-name> -p '{"spec":{"replicas":3}}'

# Replace resource
kubectl replace -f <file>

# Apply changes
kubectl apply -f <file>

# Set resource limits
kubectl set resources deployment <deployment-name> -c=<container-name> --limits=cpu=200m,memory=512Mi

# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets

# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Uncordon node
kubectl uncordon <node-name>
```

## Advanced Commands

```bash
# Diff before applying
kubectl diff -f <file>

# Explain resource definition
kubectl explain <resource>
kubectl explain pod.spec.containers

# Run temporary pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Create job
kubectl create job <job-name> --image=<image>

# List jobs
kubectl get jobs

# List cronjobs
kubectl get cronjobs

# Create from stdin
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
  - name: nginx
    image: nginx
EOF

# Label resources
kubectl label pods <pod-name> <label-key>=<label-value>

# Annotate resources
kubectl annotate pods <pod-name> <annotation-key>=<annotation-value>

# Taint node
kubectl taint nodes <node-name> <key>=<value>:<effect>

# Remove taint from node
kubectl taint nodes <node-name> <key>:<effect>-
```

## Useful Aliases

Add these to your shell configuration file (.bashrc, .zshrc, etc.):

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kgpa='kubectl get pods --all-namespaces'
alias kga='kubectl get all'
alias kctx='kubectl config current-context'
```

## Tips and Best Practices

1. **Use kubectl autocomplete**: 
   ```bash
   source <(kubectl completion bash)  # for bash
   source <(kubectl completion zsh)   # for zsh
   ```

2. **Use short names for resources**:
   - pods (po)
   - services (svc)
   - deployments (deploy)
   - namespaces (ns)
   - configmaps (cm)
   - persistentvolumes (pv)
   - persistentvolumeclaims (pvc)

3. **Use `-o wide` for more details without full describe**

4. **Use `--dry-run=client -o yaml` to generate YAML**:
   ```bash
   kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
   ```

5. **Use labels effectively** for organizing and selecting resources

6. **Always specify namespace** with `-n` flag or set default namespace

7. **Use `kubectl explain`** to understand resource specifications

8. **Keep your kubectl version close to your cluster version** (within one minor version)

## Common Troubleshooting Scenarios

### Pod not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### Service not accessible
```bash
kubectl get endpoints <service-name>
kubectl describe service <service-name>
kubectl get pods -l <service-selector>
```

### Node issues
```bash
kubectl describe node <node-name>
kubectl get nodes
kubectl top nodes
```

### Resource quota issues
```bash
kubectl describe resourcequota -n <namespace>
kubectl describe limitrange -n <namespace>
```
