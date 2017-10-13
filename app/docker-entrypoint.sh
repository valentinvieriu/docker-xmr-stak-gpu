#!/bin/bash
set -x

envtpl /app/xmr-stak-gpu.conf.tpl -o /app/xmr-stak-gpu.conf --allow-missing --keep-template

if [ "$1" = 'xmr-stak-nvidia' ]; then
    exec /app/xmr-stak-nvidia /app/xmr-stak-gpu.conf
fi

exec "$@"
