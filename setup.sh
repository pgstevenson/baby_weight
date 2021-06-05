#!/bin/sh

docker build -t pgstevenson/baby_weight -f ./webapp/Dockerfile .
docker build -t pgstevenson/baby_weight_api ./api

docker-compose up -d
