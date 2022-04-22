#!/bin/sh

set -e

function main() {
  echo ""

  DOCKER_REGISTRY=ghcr.io
  translateDockerTag

  GITHUB_DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${GITHUB_REPOSITORY_OWNER}/${INPUT_NAME}:${IMAGE_TAG}

  echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ${GITHUB_DOCKER_REGISTRY}
  docker pull ${GITHUB_DOCKER_IMAGE_NAME}
  docker logout ${GITHUB_DOCKER_REGISTRY}

  GCR_REGISTRY=${INPUT_GCRREGION}-docker.pkg.dev
  GCR_IMAGE_NAME=${GCR_REGISTRY}/${INPUT_GCRPROJECT}/${INPUT_GCRREPO}/${INPUT_GCRNAME}:${IMAGE_TAG}

  echo ${INPUT_GCRJSONKEY} | docker login -u _json_key --password-stdin ${GCR_REGISTRY}
  docker tag ${GITHUB_DOCKER_IMAGE_NAME} ${GCR_IMAGE_NAME}
  docker push ${GCR_IMAGE_NAME}
  docker logout
}

function translateDockerTag() {
  if isOnMaster; then
    IMAGE_TAG="latest"
  elif isOnReleaseBranch; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\/release\///g")-rc
  elif isOnVersionBranch; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\/v\([[:digit:]]*.[[:digit:]]*\)/\1/g")
  elif isGitTag; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/tags\/v\([[:digit:]]*.[[:digit:]]*\).[[:digit:]]*/\1/g")
  else
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")
  fi;
}

function isOnMaster() {
  [ "${GITHUB_REF}" = "refs/heads/master" ]
}

function isOnReleaseBranch() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/heads\/release\///g") != "${GITHUB_REF}" ]
}

function isOnVersionBranch() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/heads\/v//g") != "${GITHUB_REF}" ]
}

function isGitTag() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/tags\///g") != "${GITHUB_REF}" ]
}

main
