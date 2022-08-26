#!/bin/bash
set -euxo pipefail

[ -n "${apt_cache_host:-}" ] || exit 0

cat >/etc/apt/apt.conf.d/00apt_proxy <<EOF
Acquire {
    HTTP::Proxy "http://${apt_cache_host}:${apt_cache_port:-3142}";
    HTTPS::Proxy "http://${apt_cache_host}:${apt_cache_port:-3142}";
}
EOF
