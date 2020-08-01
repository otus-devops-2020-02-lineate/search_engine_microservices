# Docker Compose Runbook

For local test of the Search Engine application use docker-compose

- Create and customize environment variables for services:

      cd ./docker
      cp .env.template .env

- Start UI, DB and MQ

      docker-compose up -d ui mongodb rabbitmq

- Start Crawler against some URL

      docker-compose run -p 8001:8000 -d crawler URL

  According to [Crawler documentation](https://github.com/express42/search_engine_crawler)
  a first try URL should be `https://github.com/express42/search_engine_crawler`

      docker-compose run -p 8001:8000 -d crawler https://github.com/express42/search_engine_crawler

- Stop all services

      docker-compose down
