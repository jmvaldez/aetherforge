#!/usr/bin/env bash
# PX4 SIH SITL entrypoint - patches MAVLink to target the Docker host,
# then launches the pre-built PX4 binary.
set -euo pipefail

FIRMWARE_DIR=/opt/px4
MAVRC=${FIRMWARE_DIR}/build/etc/init.d-posix/px4-rc.mavlink

# --- Resolve the host IP ------------------------------------------------
# Docker Desktop (macOS/Windows/Linux VM): use host.docker.internal
# Docker Engine (native Linux): use the default gateway
if getent ahostsv4 host.docker.internal &>/dev/null; then
    HOST_IP=$(getent ahostsv4 host.docker.internal | head -1 | awk '{print $1}')
    echo "Docker Desktop detected — targeting host at ${HOST_IP}"
else
    HOST_IP=$(ip route | awk '/default/ {print $3}')
    echo "Docker Engine detected — targeting gateway at ${HOST_IP}"
fi

# --- Patch MAVLink to send telemetry to the host ------------------------
# Append "-t <IP>" to the GCS and offboard mavlink start commands so PX4
# pushes data out of the container instead of broadcasting inside it.
sed -i "s/mavlink start -x -u \$udp_gcs_port_local -r 4000000/& -t ${HOST_IP}/" "${MAVRC}"
sed -i "s/mavlink start -x -u \$udp_offboard_port_local -r 4000000/& -t ${HOST_IP}/" "${MAVRC}"

# --- Spawn offset ------------------------------------------------------
# Shift home by SPAWN_N_M / SPAWN_E_M metres so drones spawn around the
# shared PX4_HOME point instead of on top of each other. Flat-earth approx.
if [[ -n "${PX4_HOME_LAT:-}" && -n "${PX4_HOME_LON:-}" ]]; then
    read -r PX4_HOME_LAT PX4_HOME_LON < <(awk \
        -v lat="${PX4_HOME_LAT}" -v lon="${PX4_HOME_LON}" \
        -v n="${SPAWN_N_M:-0}" -v e="${SPAWN_E_M:-0}" \
        'BEGIN { pi = atan2(0, -1)
                 printf "%.7f %.7f\n", lat + n / 111320,
                        lon + e / (111320 * cos(lat * pi / 180)) }')
    export PX4_HOME_LAT PX4_HOME_LON
    echo "Spawning at ${PX4_HOME_LAT}, ${PX4_HOME_LON} (offset N ${SPAWN_N_M:-0} m, E ${SPAWN_E_M:-0} m)"
fi

# --- Launch PX4 ----------------------------------------------------------
cd "${FIRMWARE_DIR}/build"
exec ./bin/px4 -i ${PX4_INSTANCE:-0} -d
