FROM k8s.gcr.io/node-problem-detector:v0.6.2

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl awscli util-linux

COPY plugin/spot_termination.sh /config/plugin/
COPY plugin/launch_config_drift.sh /config/plugin/
COPY plugin/uptime.sh /config/plugin/
