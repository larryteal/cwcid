# Cloudflare Warp Client In Docker (for testing)

## Start docker container
```bash
docker run -it --rm \
  --cap-add=NET_ADMIN \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
   ubuntu:24.04 bash
```

## Install dependencies and turn on cloudflare warp
```bash
cat > start.sh << 'EOF'
#!/bin/bash

set -e
apt-get update
apt-get install -y curl gnupg lsb-release sudo
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
apt-get update
apt-get install -y cloudflare-warp
apt-get clean
rm -rf /var/lib/apt/lists/*
mkdir -p /root/.local/share/warp
echo -n 'yes' > /root/.local/share/warp/accepted-tos.txt
mkdir -p /dev/net
(mknod /dev/net/tun c 10 200 || true)
mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system
(nohup warp-svc > /var/log/warp-svc.log 2>&1 &)
sleep 2
warp-cli registration new
# cat /var/lib/cloudflare-warp/reg.json
warp-cli connect
sleep 2
curl https://www.cloudflare.com/cdn-cgi/trace/
EOF
```
```bash
bash start.sh
```

# Usage

```bash
docker run -d \
  --name vpn \
  --cap-add=NET_ADMIN \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --health-cmd="curl -fsSL https://www.cloudflare.com/cdn-cgi/trace/ | grep warp=on || exit 1" \
  --health-interval=5s \
  --health-timeout=3s \
  --health-retries=5 \
  --health-start-period=5s \
  --restart unless-stopped \
  larryteal/cwcid:latest
```
```bash
docker run --rm --network=container:vpn alpine/curl -fsSL https://www.cloudflare.com/cdn-cgi/trace/
```

