FROM k8s.gcr.io/node-problem-detector:v0.6.2

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl awscli util-linux

COPY config /config
