# Running charts with Helm

Charts are stored at [charts](../charts) directory.
- [Crawler chart](../charts/crawler) creates backend for crawling.
- [UI chart](../charts/ui) creates frontend for searching.
- [Search Engine chart](../charts/search-engine) deploys full application.

## How to deploy application manually to Kubernetes cluster

    cd charts/search-engine
    helm dep update .
    helm install serch-engine-manual ./

## How to update manually deployed application

    cd charts/search-engine
    helm dep update .
    helm upgrade serch-engine-manual ./

## How to delete manually deployed application

    cd charts/search-engine
    helm del serch-engine-manual
