
# How to Redeploy Changes to a Kubernetes Manifest

To redeploy changes to a Kubernetes resource (such as Elasticsearch, Suricata, or others), follow these steps:

1. **Update the Manifest**- Edit the relevant deployment YAML file or Jinja2 template with your changes.

1. **Render the Template** (if using Jinja2)- Render the template to produce the final YAML file.

1. **Apply the Changes**

- Run:

```sh
kubectl apply -f your-resource.yaml
```

This command updates or redeploys only the specified resource in your cluster. There is no need to redeploy the entire cluster or control plane. This is the standard Kubernetes workflow for updating or redeploying services.
