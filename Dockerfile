# syntax=docker/dockerfile:1.4
FROM quay.io/helmpack/chart-testing:v3.5.1

# Change working directory:
WORKDIR /work

# Volumes:
VOLUME [ "/work" ]

# Run once the container has started:
ENTRYPOINT [ "ct" ]
