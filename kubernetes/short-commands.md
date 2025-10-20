# Kubernetes Short Commands

A collection of frequently used Kubernetes commands and shortcuts.

## Pods

### List pods
```bash
# List all pods in current namespace
kubectl get pods

# List all pods in all namespaces
kubectl get pods -A
kubectl get pods --all-namespaces

# List pods with more details
kubectl get pods -o wide

# Watch pod status
kubectl get pods -w
```

### Describe and logs
```bash
# Describe a pod
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>

# Get logs from previous container
kubectl logs <pod-name> --previous

# Get logs from specific container in pod
kubectl logs <pod-name> -c <container-name>
```

### Execute commands in pods
```bash
# Execute a command in a pod
kubectl exec <pod-name> -- <command>

# Get interactive shell
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh

# Execute in specific container
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

### Delete pods
```bash
# Delete a pod
kubectl delete pod <pod-name>

# Force delete a pod
kubectl delete pod <pod-name> --force --grace-period=0

# Delete all pods in namespace
kubectl delete pods --all
```

## Deployments

### List and describe deployments
```bash
# List deployments
kubectl get deployments
kubectl get deploy

# Describe deployment
kubectl describe deployment <deployment-name>
```

### Scale deployments
```bash
# Scale deployment
kubectl scale deployment <deployment-name> --replicas=<count>

# Autoscale deployment
kubectl autoscale deployment <deployment-name> --min=<min> --max=<max> --cpu-percent=<percent>
```

### Update and rollback
```bash
# Update image
kubectl set image deployment/<deployment-name> <container-name>=<new-image>

# Rollout status
kubectl rollout status deployment/<deployment-name>

# Rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision>

# Restart deployment
kubectl rollout restart deployment/<deployment-name>
```

## Services

### List and describe services
```bash
# List services
kubectl get services
kubectl get svc

# Describe service
kubectl describe service <service-name>
```

### Port forwarding
```bash
# Forward port from service
kubectl port-forward service/<service-name> <local-port>:<service-port>

# Forward port from pod
kubectl port-forward <pod-name> <local-port>:<pod-port>
```

## ConfigMaps and Secrets

### ConfigMaps
```bash
# List configmaps
kubectl get configmaps
kubectl get cm

# Describe configmap
kubectl describe configmap <configmap-name>

# Create configmap from file
kubectl create configmap <name> --from-file=<path>

# Create configmap from literal
kubectl create configmap <name> --from-literal=<key>=<value>
```

### Secrets
```bash
# List secrets
kubectl get secrets

# Describe secret
kubectl describe secret <secret-name>

# Create secret
kubectl create secret generic <name> --from-literal=<key>=<value>

# Get secret data (base64 encoded)
kubectl get secret <secret-name> -o jsonpath='{.data}'
```

## Namespaces

### Namespace operations
```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace <namespace-name>

# Delete namespace
kubectl delete namespace <namespace-name>

# Set default namespace for context
kubectl config set-context --current --namespace=<namespace-name>
```

## Context and Config

### Context management
```bash
# Get current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# View config
kubectl config view
```

## Resources

### General resource commands
```bash
# Get all resources
kubectl get all

# Get specific resource type
kubectl get <resource-type>

# Delete resource
kubectl delete <resource-type> <resource-name>

# Edit resource
kubectl edit <resource-type> <resource-name>

# Apply configuration
kubectl apply -f <file.yaml>

# Delete from configuration
kubectl delete -f <file.yaml>
```

### Resource output formats
```bash
# YAML output
kubectl get <resource> <name> -o yaml

# JSON output
kubectl get <resource> <name> -o json

# Wide output
kubectl get <resource> -o wide

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

## Useful Aliases

Add these to your `.bashrc` or `.zshrc`:

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
```

## Debug and Troubleshooting

### Node operations
```bash
# List nodes
kubectl get nodes

# Describe node
kubectl describe node <node-name>

# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Drain node
kubectl drain <node-name> --ignore-daemonsets

# Uncordon node
kubectl uncordon <node-name>
```

### Events
```bash
# Get events
kubectl get events

# Get events sorted by timestamp
kubectl get events --sort-by='.lastTimestamp'

# Watch events
kubectl get events -w
```

### Resource usage
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods

# Pod resource usage in all namespaces
kubectl top pods -A
```

## Quick Tips

- Use `kubectl explain <resource>` to get documentation for a resource
- Use `kubectl api-resources` to list all available resource types
- Use `kubectl completion bash` or `kubectl completion zsh` for shell completion
- Use `-n <namespace>` to specify namespace for any command
- Use `--dry-run=client -o yaml` to preview YAML without applying
