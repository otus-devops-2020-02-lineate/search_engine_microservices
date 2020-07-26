# Monitoring

Add Helm 3 repository

    helm repo add bitnami https://charts.bitnami.com/bitnami

(_Optional_) Pull Prometheus Operator chart from the repo

    helm pull --untar bitnami/prometheus-operator --version 0.26.0

Install Prometheus Operator using Helm3

    helm upgrade --install prometheus bitnami/prometheus-operator --version 0.26.0 \
        --set "prometheus.ingress.enabled=true" \
        --set "prometheus.ingress.hosts[0].name=prometheus.search-engine" \
        --set "alertmanager.ingress.enabled=true" \
        --set "alertmanager.ingress.hosts[0].name=alertmanager.search-engine"

Wait for Prometheus resources to be ready

    watch -n 2 kubectl get all

Check for overriden chart values

    helm get values prometheus

Add following as `/etc/hosts` aliases for cluster nginx IP:

    prometheus.search-engine alertmanager.search-engine

Now you can hit them via http

## Search Enginge metrics

_coming soon..._
