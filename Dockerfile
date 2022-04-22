FROM docker:stable
LABEL org.opencontainers.image.source=https://github.com/deeepvision/github-action-docker-gcr

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]
