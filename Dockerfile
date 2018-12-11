FROM k8s.gcr.io/node-problem-detector:v0.5.0

COPY plugin/spot_termination.sh /config/plugin/
