FROM python:3.6.0-alpine

WORKDIR /app
COPY . .

RUN apk --no-cache --update add build-base gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del build-base gcc musl-dev

ENV MONGO         mongodb
ENV MONGO_PORT    27017
ENV RMQ_HOST      rabbitmq
ENV RMQ_QUEUE     urls
ENV RMQ_USERNAME  rabbitmq
ENV RMQ_PASSWORD  rabbitmq
ENV CHECK_INTERVAL 60
ENV EXCLUDE_URLS   ""

ENTRYPOINT ["python3", "-u", "crawler/crawler.py"]
