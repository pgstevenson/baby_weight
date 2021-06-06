FROM python:alpine

MAINTAINER Paul Stevenson "pstevenson6@gmail.com"

COPY ./app /app

WORKDIR /app

# add and install requirements
RUN apk update && apk upgrade && \
  apk add postgresql-libs && \
  apk add --no-cache --virtual .build-deps build-base gcc musl-dev libffi-dev postgresql-dev && \
  python3 -m pip install -r requirements.txt --no-cache-dir && \
  apk --purge del .build-deps

COPY ./01_flask_api.py /app/app.py
COPY ./py /app/py

ENTRYPOINT ["python"]

EXPOSE 5000

CMD ["app.py"]
