#!/bin/sh

# build images if changes have been made:
# docker build -t pgstevenson/baby_weight -f ./webapp/Dockerfile .
# docker build -t pgstevenson/baby_weight_api ./api

# pull baby_weight image from Docker Hub
docker pull pgstevenson/baby_weight:latest

docker-compose up -d
