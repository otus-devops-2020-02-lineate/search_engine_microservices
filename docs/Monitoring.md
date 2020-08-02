# Monitoring

## Prerequisites

Nginx is expected to be already installed into Kubernetes cluster

## Prometheus

Add Helm 3 [Bitnami](https://hub.helm.sh/charts/bitnami) repository

    helm repo add bitnami https://charts.bitnami.com/bitnami

(_Optional_) Pull Prometheus Operator chart from the repo

    helm pull --untar bitnami/prometheus-operator --version 0.26.0

Install Prometheus Operator using Helm3

    cd ./charts/prometheus-operator
    helm upgrade --install prometheus bitnami/prometheus-operator --version 0.26.0 -f custom_values.yaml

Wait for Prometheus resources to be ready

    watch -n 2 kubectl get all

Check for overriden chart values

    helm get values prometheus

Add following as `/etc/hosts` aliases for cluster nginx IP:

    <nginx_ip> prometheus.search-engine alertmanager.search-engine

Where `nginx_ip` could be found from output:

    kubectl get svc nginx -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'

Now you can hit them via http

## Search Engine metrics

Add Crawler and UI ServiceMonitors to scrape Search Engine metrics to Prometheus

    kubectl apply -f ./charts/prometheus-operator/search-engine-service-monitors.yaml

Now metrics are available in Prometheus as they are declared in
[Crawler](https://github.com/otus-devops-2020-02-lineate/search_engine_crawler#%D0%BC%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%BD%D0%B3)
and [UI](https://github.com/otus-devops-2020-02-lineate/search_engine_crawler#%D0%BC%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%BD%D0%B3) documentation

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
        kubectl create configmap grafana-search-engine-metrics --from-file=./dashboards/search-engine-metrics.json
    }

Install Grafana using Helm3

    helm upgrade --install grafana bitnami/grafana --version 3.3.1 -f custom-values.yaml

Wait till all Grafana resources become running and ready

    watch -n 5 kubectl get all

Add `grafana.search-engine` as an alias for cluster nginx IP

    <nginx_ip> grafana.search-engine

Where `nginx_ip` could be found from output:

    kubectl get svc nginx -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
