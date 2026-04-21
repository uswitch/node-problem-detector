FROM registry.k8s.io/node-problem-detector/node-problem-detector:v1.35.2

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    # required by plugin/spot_termination.sh
    curl \
    # required by plugin/local_dns_resolver.sh
    jq \
    # required by local_dns_resolver.sh and upstream_dns_resolver.sh plugins
    dnsutils \
  ; \
  rm -rf /var/lib/apt/lists/*;

COPY config /config
