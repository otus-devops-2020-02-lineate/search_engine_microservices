# search_engine_microservices

Otus DevOps Tools & Practices 2020-02 - Project Work

## Docs

- [Prerequisites](./docs/Prerequisites.md) -
  _Configure GCP. Work with the repo_

- [Docker Compose Runbook](./docs/Docker-compose-runbook.md) -
  _Local testing_

- [Terraform Runbook](./docs/Terraform-runbook.md) -
  _Deploy Kubernetes infrastructure in GCP_

- Manual Kubernetes deployment with Helm
  - [Install Helm](./docs/Helm-installation.md)
  - [Release the app](./docs/Helm-charts-running.md)

- Gitlab CI
  - [Install Gitlab](./docs/Gitlab-CI-installation.md)
  - [Configure](./docs/Gitlab-CI-configuration.md)

- Monitoring & Logging

  - [Install Prometheus & Grafana](./docs/Monitoring.md)

## How to ramp up infrastructure and release

Make sure to check all prereq

Use single one-line command to
 - bring up GCP infrastructure
 - install nginx (with Gitlab chart) as a single LoadBalancer with external IP for all project resources
 - install and configure Gitlab server.
 - release app `master` branch to **staging** and **production** environments
 - deploy components for monitoring


       make infra_launch

You will be prompted to define
 - GCP project ID
 - Terraform backend s3 bucket name
 - Gitlab params:
    - Private token
    - SSH pubkey for code pushing
    - Group name for search-engine repos
    - Docker Hub username, password

## Maintainers

 - [Nikita Shvyryaev](https://github.com/nshvyryaev)
 - [Georgy Vashchenko](https://github.com/gvashchenkolineate)
