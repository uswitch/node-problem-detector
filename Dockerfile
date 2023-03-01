FROM registry.k8s.io/node-problem-detector/node-problem-detector:v0.8.12

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    # required by plugin/spot_termination.sh
    curl \
    # required by plugin/launch_config_drift.sh
    awscli \
    jq \
    # required by local_dns_resolver.sh and upstream_dns_resolver.sh plugins
    dnsutils \
  ; \
  rm -rf /var/lib/apt/lists/*;

COPY config /config
