#!/bin/bash

TAG="$DEPLOY_SERVER/$DEPLOY_PROJECT/$DEPLOY_IMAGE:latest"

echo $DEPLOY_TOKEN | docker login -u $DEPLOY_USER --password-stdin $DEPLOY_SERVER
docker build -t $TAG .
docker push $TAG
