FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       curl \
       dbus \
       docker.io \
       iproute2 \
       iptables \
       openssh-server \
       procps \
       python3 \
       sudo \
       systemd \
       systemd-sysv \
       ufw \
       util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash debian \
    && usermod --append --groups sudo debian \
    && mkdir -p /run/sshd /etc/ssh/sshd_config.d \
    && printf '%s\n' \
       'PermitRootLogin yes' \
       'PasswordAuthentication yes' \
       'PubkeyAuthentication yes' \
       'UsePAM no' \
       'X11Forwarding no' \
    'AllowUsers debian deployer' \
       > /etc/ssh/sshd_config.d/lab.conf \
   && printf '%s\n' 'debian ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/lab-bootstrap \
   && chmod 0440 /etc/sudoers.d/lab-bootstrap \
    && systemctl enable ssh docker

COPY dockerfiles/target-entrypoint.sh /usr/local/bin/target-entrypoint
RUN chmod 0755 /usr/local/bin/target-entrypoint

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/usr/local/bin/target-entrypoint"]
CMD ["/sbin/init"]
