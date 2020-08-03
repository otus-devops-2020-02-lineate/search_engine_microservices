# Prerequisites

## GCP

- Create new project in CGP [console](https://console.cloud.google.com/compute)

- Install [GCloud SDK](https://cloud.google.com/sdk/)

- Run `gcloud init`, select the account and grant the access,
  pick the cloud project to use

## Pre-commit hooks

- Install pip

- Install [pre-commit](https://pre-commit.com/)

      pip install pre-commit

- Install pre-commit hooks
  Assuming .github/.pre-commit-config.yaml exists

      cd ./.github
      pre-commit install

## Github integration

- Install Github app to Slack: [link](https://get.slack.help/hc/en-us/articles/232289568-GitHub-for-Slack)

- Add Github to a conversation posting the message.
  (Confirm appropriate Github access requests)

      /github subscribe otus-devops-2020-02-lineate/search_engine_microservices commits:all

## Submodules

    git submodule add https://github.com/express42/search_engine_crawler ./src/search_engine_crawler/
    git submodule add https://github.com/express42/search_engine_ui ./src/search_engine_ui/
