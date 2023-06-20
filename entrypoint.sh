#!/bin/bash

set -e
set -o pipefail

run_server() {
    LOG_FILE="/svrstat/logs/stat_server.log"

    nginx
    nohup /svrstat/stat_server -c config.toml &> ${LOG_FILE} &
    exec tail -F ${LOG_FILE}
}

run_client() {
    PROCFS_PATH=${PROCFS_PATH:-/proc}
    SYSFS_PATH=${SYSFS_PATH:-/sys}

    sed -ri \
      -e "s@^;(Interface ).*@\1\"${SSR_IFACE}\"@" \
      -e "s@^;(ProcfsPath ).*@\1\"${PROCFS_PATH}\"@" \
      -e "s@^;(SysfsPath ).*@\1\"${SYSFS_PATH}\"@" \
      /etc/vnstat.conf
    vnstatd -d
    exec /svrstat/stat_client
}

run_pyclient() {
    PROCFS_PATH=${PROCFS_PATH:-/proc}
    SYSFS_PATH=${SYSFS_PATH:-/sys}

    sed -ri \
      -e "s@^;(Interface ).*@\1\"${SSR_IFACE}\"@" \
      -e "s@^;(ProcfsPath ).*@\1\"${PROCFS_PATH}\"@" \
      -e "s@^;(SysfsPath ).*@\1\"${SYSFS_PATH}\"@" \
      /etc/vnstat.conf
    vnstatd -d
    exec python3 -u /svrstat/stat_client.py
}

help() {
    echo "Usage:"
    echo "    docker run ... server           # start vnstat, nginx and stat_server"
    echo "    docker run ... client           # start stat_client"
    echo "    docker run ... pyclient         # start stat_client.py"
    echo "    "
}

if test -z "$1"; then
    help
    exit 0
fi

case "$1" in
    server)
        run_server
        ;;
    client)
        run_client
        ;;
    pyclient)
        run_pyclient
        ;;
    *)
        exec "$@"
        ;;
esac
