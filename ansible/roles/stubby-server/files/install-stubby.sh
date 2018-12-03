#!/bin/sh

# Franz Santoso -- 2018
# /u/franksn
# pihole

exists () {
  if [ -z ${1:+command} ]
    then
      echo 'command: parameter not set or null' >&2
      return 1
  fi

  command "$1" --version >/dev/null 2>&1

  if [ $? -eq 127 ]
    then
      echo "$1: not found" >&2
      return 127
  fi
}

help() {
    printf "\t%s\n" "Usage: $0 <install_prefix_dir> <ip_addresses> <port>"
    printf "\t%s\n" "ip_addresses argument are comma separated, without spaces"
    printf "\t%s\n" "example: $0 /usr/local 127.0.2.2,0::2 5053"
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    echo "script should be run as root / superuser"
    exit 1
fi

if [ "$#" -ne 3 ]; then
    help
fi

GETDNSDIR=/tmp/getdns
PREFIXDIR="$1"
ADDRv4="${2%%,*}"
ADDRv6="${2#*,}"
PORT="$3"

exists git 2>&1 || {
    printf "%s\n" "Installing git..."
    apt install -y -qq git
}

testPrefix() {
    if [ ! -d "$PREFIXDIR" ]; then
        printf "%s\n" "Error: The specified prefix dir doesn't exists"
        exit 1
    fi
}

installDeps() {
    apt install -y -qq build-essential libssl-dev libtool \
        m4 autoconf automake libyaml-dev libev4 libevent-core-2.0.5 \
        libuv1 curl
}

cloneRepo() {
    if [ ! -d "$GETDNSDIR" ]; then
        mkdir -v "$GETDNSDIR"
    fi
    git clone https://github.com/getdnsapi/getdns.git "$GETDNSDIR"
    cd "$GETDNSDIR"
    git checkout develop
    git submodule update --init
    libtoolize -ci
    autoreconf -fi
    mkdir -vp "$GETDNSDIR"/build && cd "$GETDNSDIR"/build
}

buildStubby() {
    cd "$GETDNSDIR"/build
    ../configure --prefix="$PREFIXDIR" --without-libidn --without-libidn2 \
        --enable-stub-only --with-stubby
    make && make install
}

patchConfig() {
    curl -sSL "https://gist.githubusercontent.com/FrankSantoso/3556a9afb92d3ec789bd449dc0d9c68a/raw/2e71ec342ee0c25ebffe12d7979b64691fe1eef2/stubby-config.diff" \
        -o /tmp/stubby-config.diff
    cd "$GETDNSDIR"/stubby
    cp stubby.yml.example stubby.yml
    patch < /tmp/stubby-config.diff
    perl -i -pe"s/127.0.0.1/$ADDRv4/g" stubby.yml
    perl -i -pe"s/0::1/$ADDRv6/g" stubby.yml
    perl -i -pe"s/5353/$PORT/g" stubby.yml
    /usr/bin/install -Dm644 stubby.yml /etc/stubby.yml
}

patchService() {
    curl -sSL "https://gist.githubusercontent.com/FrankSantoso/71bada98a6ac983a3ce1be565c66aade/raw/bb408edf3d68b2e6942dc8be9f504ea3472782e3/stubby-service.diff" \
         -o /tmp/stubby-service.diff
    cd "$GETDNSDIR"/stubby/systemd
    patch < /tmp/stubby-service.diff
    cp stubby.service stubby.service.tmp
    perl -i -pe"s@/usr/local@$PREFIXDIR@g" stubby.service.tmp
    /usr/bin/install -Dm644 stubby.service.tmp \
        /lib/systemd/system/stubby.service
    /usr/bin/install -Dm644 stubby.conf /usr/lib/tmpfiles.d/stubby.conf
}

addToDnsmasq() {
    if [ -d /etc/dnsmasq.d ]; then
        for i in "$ADDRv4" "$ADDRv6"; do
            echo "server=$i#$PORT" >> /etc/dnsmasq.d/02-stubby.conf
        done
    fi
}

cleanup() {
    rm -rf "$GETDNSDIR" /tmp/stubby-service.diff /tmp/stubby-config.diff
}

printf "%s\n" "Installing build dependencies..."
installDeps
printf "%s\n" "Cloning git repo..."
cloneRepo
printf "%s\n" "Building and Installing Stubby to $1/bin/stubby"
buildStubby
printf "%s\n" "Patching and installing config..."
patchConfig
printf "%s\n" "Patching and installing service..."
patchService
printf "%s\n" "Adding dns to dnsmasq config..."
addToDnsmasq
printf "%s\n" "Starting and Enabling stubby.service..."
systemctl enable stubby && systemctl start stubby
printf "%s\n" "Done, You might need to restart pihole and dnsmasq"
cleanup
