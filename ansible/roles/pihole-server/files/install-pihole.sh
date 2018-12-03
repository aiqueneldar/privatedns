#!/bin/bash

TMPDIR=/tmp/pihole-install
if [ ! -d "$TMPDIR" ]; then
	mkdir -p "$TMPDIR"
fi

cd $TMPDIR

git clone --depth 1 https://github.com/pi-hole/pi-hole.git Pi-hole
cd "Pi-hole/automated install/"
bash basic-install.sh --unattended
