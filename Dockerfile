FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release sudo && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    apt-get install -y cloudflare-warp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.local/share/warp && \
    echo -n 'yes' > /root/.local/share/warp/accepted-tos.txt && \
    mkdir -p /run/dbus && \
    rm -f /run/dbus/pid

CMD ["/bin/sh", "-c", "\
    dbus-daemon --system \
    && sleep 1 \
    && mkdir -p /dev/net \
    && (mknod /dev/net/tun c 10 200 || true) \
    && (nohup warp-svc > /var/log/warp-svc.log 2>&1 &) \
    && sleep 3 \
    && warp-cli registration new \
    && warp-cli connect \
    && tail -f /var/log/warp-svc.log \
"]
