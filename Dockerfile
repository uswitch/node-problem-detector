FROM k8s.gcr.io/node-problem-detector:v0.6.4

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    # required by plugin/spot_termination.sh
    curl \
    # required by plugin/launch_config_drift.sh
    awscli \
    jq \
  ; \
  rm -rf /var/lib/apt/lists/*;

COPY config /config
