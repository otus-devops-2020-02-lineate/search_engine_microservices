# Monitoring

## Prometheus

Add Helm 3 [Bitnami](https://hub.helm.sh/charts/bitnami) repository

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

    <nginx_ip> prometheus.search-engine alertmanager.search-engine

Where `nginx_ip` could be found from output:

    kubectl get svc nginx -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

Now you can hit them via http

## Grafana

(_Optional_) Pull Grafana chart from the repo

    helm pull --untar bitnami/grafana --version 3.3.1

Create a k8s secret that will contain Grafana datasource (Prometheus)
and ConfigMaps for dashboards (see details [here](https://hub.helm.sh/charts/bitnami/grafana)).
This will add the most popular dashboards for K8s -
[Kubernetes cluster monitoring (via Prometheus)](https://grafana.com/grafana/dashboards/315)
and [Kubernetes Deployment metrics](https://grafana.com/grafana/dashboards/741)

    cd ./charts/grafana
    {
        kubectl create secret generic grafana-datasource-secret --from-file=datasources.yaml
        kubectl create configmap grafana-kubernetes-deployment-metrics --from-file=./dashboards/kubernetes-deployment-metrics.json
        kubectl create configmap grafana-kubernetes-cluster-monitoring --from-file=./dashboards/kubernetes-cluster-monitoring.json
    }

Install Grafana using Helm3

    helm upgrade --install grafana bitnami/grafana --version 3.3.1 -f custom-values.yaml

Wait till all Grafana resources become running and ready

    watch -n 5 kubectl get all

Add `grafana.search-engine` as an alias for cluster nginx IP

    <nginx_ip> grafana.search-engine

Where `nginx_ip` could be found from output:

    kubectl get svc nginx -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

## Search Enginge metrics

_coming soon..._
