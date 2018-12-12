FROM k8s.gcr.io/node-problem-detector:v0.6.1

RUN apt-get update && apt-get install -y \
  curl

COPY plugin/spot_termination.sh /config/plugin/
