#!/usr/bin/env bash
# Feature platformio-esp32: PlatformIO with the ESP-IDF toolchains of ESP32-S3, ESP32-C6 and ESP32-P4, preloaded
# Runs as root inside the build, once. This feature declares "network" in feature.json: it is the one exception to "Debian packages only".
# What it fetches is pinned: Python packages by hash (requirements-core*.txt, pip --require-hashes), the platforms by version in
# warmup/platformio.ini. Two cores, because pioarduino (ESP32-P4) needs PlatformIO Core 6.2 and the official espressif32@6 needs 6.1:
#   pio    PlatformIO Core 6.1.18   (S3, C6)        core dir /opt/pio61/core
#   pio62  pioarduino Core 6.2.0    (P4)             core dir /opt/pio62/core
#   esptool                         esptool 5.2.0 (merge-bin for the factory images)
set -euo pipefail
here="$(pwd)"
apt-get update
apt-get install -y --no-install-recommends python3 python3-venv ca-certificates git
dpkg-query -W -f='${Package} ${Version}\n' python3 python3-venv ca-certificates git

for v in 61 62; do
    python3 -m venv "/opt/pio${v}/venv"
    "/opt/pio${v}/venv/bin/pip" install --no-cache-dir --require-hashes -r "${here}/requirements-core${v}.txt"
    mkdir -p "/opt/pio${v}/core"
done

wrapper() {   # name, version
    cat > "/usr/local/bin/$1" <<WRAP
#!/bin/sh
export PLATFORMIO_CORE_DIR=/opt/pio$2/core PLATFORMIO_NO_ANSI=true PLATFORMIO_DISABLE_PROGRESSBAR=true PLATFORMIO_CHECK_PLATFORMIO_INTERVAL=0
exec /opt/pio$2/venv/bin/platformio "\$@"
WRAP
    chmod 0755 "/usr/local/bin/$1"
}
wrapper pio 61
wrapper pio62 62
ln -s /opt/pio61/venv/bin/esptool /usr/local/bin/esptool

# Warm-up: build the tiny project once per chip, so platforms, toolchains and the IDF Python environments are in the image
rm -rf /tmp/warmup && cp -r "${here}/warmup" /tmp/warmup && cd /tmp/warmup
pio run -e s3
pio run -e c6
pio62 run -e p4
cd / && rm -rf /tmp/warmup

# the build runs as user worker (uid 1000), PlatformIO writes into its core dir
chown -R 1000:1000 /opt/pio61 /opt/pio62
pio --version
pio62 --version
