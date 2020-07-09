FROM python:3.6.0-alpine

WORKDIR /app
COPY . .

RUN apk --no-cache --update add build-base gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del build-base gcc musl-dev

ENV MONGO         mongodb
ENV MONGO_PORT    27017
ENV FLASK_APP     ui.py

WORKDIR ./ui
ENTRYPOINT ["gunicorn", "ui:app"]
CMD ["-b 0.0.0.0"]
