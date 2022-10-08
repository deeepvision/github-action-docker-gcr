#!/bin/sh

set -e

function main() {
  echo ""

  GITHUB_DOCKER_REGISTRY=ghcr.io
  translateDockerTag

  if [ -z "${INPUT_GITHUBNAME}" ]; then
    GITHUB_DOCKER_IMAGE_NAME=${GITHUB_DOCKER_REGISTRY}/${GITHUB_REPOSITORY}:${IMAGE_TAG}
  else
    GITHUB_DOCKER_IMAGE_NAME=${GITHUB_DOCKER_REGISTRY}/${GITHUB_REPOSITORY_OWNER}/${INPUT_GITHUBNAME}:${IMAGE_TAG}
  fi

  echo "🔑 Github Container Registry: Login to ${GITHUB_DOCKER_REGISTRY}"
  echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ${GITHUB_DOCKER_REGISTRY}

  echo "👷⬇️ Github Container Registry: Pull ${GITHUB_DOCKER_IMAGE_NAME}"
  docker pull ${GITHUB_DOCKER_IMAGE_NAME}

  echo "🔑 Github Container Registry: Logout"
  docker logout ${GITHUB_DOCKER_REGISTRY}

  GCR_REGISTRY=${INPUT_GCRREGION}-docker.pkg.dev
  GCR_IMAGE_NAME=${GCR_REGISTRY}/${INPUT_GCRPROJECT}/${INPUT_GCRREPO}/${INPUT_GCRNAME}:${IMAGE_TAG}

  echo "🔑 GCP Artifact Registry: Login to ${GCR_REGISTRY}"
  echo ${INPUT_GCRJSONKEY} | docker login -u _json_key --password-stdin ${GCR_REGISTRY}
  docker tag ${GITHUB_DOCKER_IMAGE_NAME} ${GCR_IMAGE_NAME}

  echo "👷⬆️ GCP Artifact Registry: Push ${GCR_IMAGE_NAME}"
  docker push ${GCR_IMAGE_NAME}

  echo "🔑 GCP Artifact Registry: Logout"
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
