# Deploy/Redeploy with a Configuration

This guide explains how to deploy or redeploy your application using Ansible and Kubernetes, including explanations for command-line options.

## Steps

1. **Navigate to your Ansible playbooks directory**

    ```bash
    cd core/playbooks
    ```
    This command changes your current directory to where your Ansible playbooks are stored.

2. **Run the Ansible playbook**

    ```bash
    ansible-playbook site.yml --tags <tag> -v
    ```
    - `ansible-playbook`: Runs an Ansible playbook.
    - `site.yml`: The main playbook file to execute.
    - `--tags <tag>`: Runs only the tasks tagged with `<tag>`. The double dash (`--`) indicates a long option.
    - `-v`: Enables verbose output, showing more details during execution. The single dash (`-`) is used for short options.

## (Optional) Monitor the Deployment

- To watch the status of your pods after deployment, use:

  ```bash
  kubectl get pods -l app=<pod-name> -w
  ```
  - `kubectl get pods`: Lists all pods.
  - `-l app=<pod-name>`: Filters pods by the label `app=<pod-name>`. The single dash (`-l`) is a short option for label selector.
  - `-w`: Watches for changes in real time. The single dash (`-w`) is a short option for "watch".

This process helps ensure your configuration is deployed correctly and allows you to monitor its status.