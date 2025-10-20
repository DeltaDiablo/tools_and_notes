# getting the URL for the Elasticsearch service

To get the Elasticsearch service URL with kubectl, follow these steps (example outputs included).

1) SSH into the controller
```bash
ssh root@<server-ip>
```
Example:
```bash
ssh root@203.0.113.10
# root@203.0.113.10's password:
# Last login: Tue Oct 20 09:12:34 2025 from 198.51.100.5
```

2) List services and find the Elasticsearch service and its NAMESPACE
```bash
kubectl get svc --all-namespaces
```
Example output (trimmed):
```text
NAMESPACE   NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kube-system kube-dns        ClusterIP   10.96.0.10     <none>        53/UDP     10d
logging     elasticsearch   ClusterIP   10.96.212.34   <none>        9200/TCP   5d
```
From this output:
- NAME = elasticsearch
- NAMESPACE = logging

3) Build the cluster DNS URL (replace NAME and NAMESPACE)
```bash
ELASTIC_URL=$(kubectl get svc <NAME> -n <NAMESPACE> -o jsonpath='{.metadata.name}.<NAMESPACE>.svc.cluster.local:9200') && echo $ELASTIC_URL
```
Example (using values from above):
```bash
ELASTIC_URL=$(kubectl get svc elasticsearch -n logging -o jsonpath='{.metadata.name}.logging.svc.cluster.local:9200') && echo $ELASTIC_URL
# Output:
# elasticsearch.logging.svc.cluster.local:9200
```

4) (Optional) Verify with curl from a pod or node that can resolve cluster DNS
```bash
curl -sS http://$ELASTIC_URL/
```
Example response (trimmed):
```json
{
    "name" : "es-node-0",
    "cluster_name" : "my-elasticsearch",
    "version" : {
        "number" : "7.10.2"
    }
}
```

Notes:
- The cluster DNS name (elasticsearch.logging.svc.cluster.local:9200) resolves inside the cluster. If you're on a node outside cluster DNS, use the service's external IP/NodePort or port-forwarding instead.
- To port-forward for local access:
```bash
kubectl port-forward -n logging svc/elasticsearch 9200:9200
# Then curl http://localhost:9200/
```