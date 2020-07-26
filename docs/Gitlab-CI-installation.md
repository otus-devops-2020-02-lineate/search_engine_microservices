# Gitlab CI installation

## Installation

- Run k8s cluster ([runbook](Terraform-runbook.md)) with this `terraform.tfvars`:

      project              = <GCP project ID>
      node_disk_size_gb    = "100"
      machine_type         = "n1-standard-2"
      region               = "europe-west1"
      zone                 = "europe-west1-b"
      node_count           = "2"
      storage_size         = "30"
      legacy_authorization = true
      logging_service      = "none"
      monitoring_service   = "none"

  This will enable lagacy authorization and custom monitoring and logging.

- Install helm ([instruction](Helm-installation.md))
- Install gitlab chart

        cd charts/gitlab-omnibus
        helm dep update
        helm install gitlab . -f values.yaml

- Wait few minutes for all gitlab k8s resources to become running and ready

        watch -n 2 kubectl get all

- To access Gitlab UI add gitlab ingress IP to /etc/hosts

        GITLAB_IP=$(kubectl get service -n nginx-ingress nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
        echo "$GITLAB_IP gitlab.search-engine staging.search-engine production.search-engine" >> /etc/hosts

_Note: you will need to add a record to hosts file for each environment created for branches._

- Open `http://gitlab.search-engine` in your browser to access gitlab
- Set you root password
