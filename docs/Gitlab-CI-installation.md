# Gitlab CI installation

## Installation

- Run k8s cluster ([runbook](Terraform-runbook.md))
- Turn legacy authentication in the cluster:
  - Login to google cloud console
  - Edit your cluster
  - Set `Legacy Authorization` enabled
  - Save
  - Wait until the cluster's ready
- Install helm ([instruction](Helm-installation.md))
- Install gitlab chart

        cd charts/gitlab-omnibus
        helm install gitlab . -f values.yaml

- Wait few minutes to let gitlab initialize and become available
- To access Gitlab UI add gitlab ingress IP to /etc/hosts

        GITLAB_IP=$(kubectl get service -n nginx-ingress nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
        echo "$GITLAB_IP gitlab-gitlab staging.search-engine production.search-engine" >> /etc/hosts

_Note: you will need to add a record to hosts file for each environment created for branches._

- Open `http://gitlab-gitlab` in your browser to access gitlab
- Set you root password
