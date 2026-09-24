#! /usr/bin/env bash

DOCKER_REGISTRY=${DOCKER_REGISTRY}
VERSION=$(jq -r .version package.json)
IMAGE=$(jq -r .name package.json)
docker build -t ${IMAGE}:${VERSION} -t ${IMAGE}:latest .
docker tag ${IMAGE}:latest ${DOCKER_REGISTRY}/${IMAGE}:latest
docker tag ${IMAGE}:${VERSION} ${DOCKER_REGISTRY}/${IMAGE}:${VERSION}
docker push ${DOCKER_REGISTRY}/${IMAGE}:${VERSION}
docker push ${DOCKER_REGISTRY}/${IMAGE}:latest

# Increment the version in package.json
jq '
  .version |= (
    split(".") | 
    [.[0], .[1], (.[2] | tonumber + 1 | tostring)] | 
    join(".")
  )
' package.json > package.json.tmp && mv package.json.tmp package.json
git add package.json
git commit -m "Bump version to ${VERSION}"
git tag -a "v${VERSION}" -m "Release version ${VERSION}"
git push origin v${VERSION}
git push origin main
