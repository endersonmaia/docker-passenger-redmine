#!/bin/bash
set -e
source /build/buildconfig
set -x

apt-get clean
ls -d -1 ${BUILD_PATH}/**/* | grep -v "cleanup.sh" | grep -v "buildconfig" | xargs rm -rf
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup

rm -f /etc/ssh/ssh_host_*
