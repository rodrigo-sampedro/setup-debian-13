FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ansible \
       bash \
       ca-certificates \
       git \
       openssh-client \
       python3 \
       python3-yaml \
       shellcheck \
       sshpass \
       sudo \
       yq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY dockerfiles/controller-entrypoint.sh /usr/local/bin/controller-entrypoint
RUN chmod 0755 /usr/local/bin/controller-entrypoint

ENTRYPOINT ["/usr/local/bin/controller-entrypoint"]
CMD ["sleep", "infinity"]
