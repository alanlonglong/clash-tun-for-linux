#!/bin/bash

cd `dirname $0`

function assert() {
    "$@"
    if [ $? != 0 ];then
        echo "Command $@ failure"
        exit 1
    fi
}

function assert_command() {
    if !which $1 > /dev/null 2> /dev/null;then
        echo "$2"
    fi
}

function _build() {
    assert_command git 'git not found'
    assert_command go 'golang support not found'

    target="linux-amd64"

    if [ "x$1" != "x" ];then
        target=$2
    fi

    rm -rf clash_build

    echo "Build clash with tun support"
    assert git clone -b add-water https://github.com/comzyh/clash clash_build

    pushd clash_build > /dev/null
    LANG=C assert make $target
    popd > /dev/null

    cp ./clash_build/bin/clash-$target ./clash
}

function _install() {
    if [ "`id -u`" != "0" ];then
        echo "Please run this script in root"
        exit 1
    fi

    assert_command systemctl "This script support systemd only"
    assert_command ip "This script support iproute2 only"

    ip rule help 2>&1 | grep "uidrange" > /dev/null 2> /dev/null
    if [ "$?" != "0" ];then
        echo "iproute2 not support uid filter"
        exit 1
    fi

    if [ ! -f "./clash" ]; then
        echo "Clash binary ./clash not found"
        echo "Try ./install.sh build to build clash with tun support"
        exit 1
    fi

    if [ ! -f "clash-setup-tun.sh" ] || [ ! -f "clash-clean-tun.sh" ]; then
        echo "Tun setup script not found"
        exit 1
    fi

    if [ ! -f "clash-tun.service" ]; then
        echo "Clash systemd unit not found"
        exit 1
    fi

    assert install -m 755 -D clash /usr/bin/clash
    assert install -m 744 -D clash-setup-tun.sh /usr/lib/clash/scripts/clash-setup-tun.sh
    assert install -m 744 -D clash-clean-tun.sh /usr/lib/clash/scripts/clash-clean-tun.sh
    assert install -m 644 -D clash-tun.service /usr/lib/systemd/system/clash-tun.service
    assert install -m 775 -d -o 65534 -g 1000 /srv/clash

    echo "Install successfully"
    echo ""
    echo "Clash Home - /srv/clash/"
    echo "Tun Device - clash0"
    echo ""
    echo "Use 'systemctl start clash-tun' to start clash"
    echo "Use 'systemctl enable clash' to enable clash start with system boot"
}

function _uninstall() {
    systemctl disable clash-tun.service --now > /dev/null 2> /dev/null

    assert rm /usr/bin/clash
    assert rm -rf /usr/lib/clash
    assert rm /usr/lib/systemd/system/clash-tun.service

    echo "Uninstall successfully"
}

function _help() {
    echo "Usage: ./install.sh ACTION [OPTIONS...]"
    echo ""
    echo "ACTION:"
    echo "    build [platform]    build clash binary with tun support (default platform 'linux-amd64')"
    echo "    install             install clash binary and tun setup scripts"
    echo "    uninstall           uninstall"
    echo ""
    exit 1
}

case "$1" in
    "install")
    shift
    _install "$@"
    ;;
    "uninstall")
    shift
    _uninstall "$@"
    ;;
    "build")
    shift
    _build "$@"
    ;;
    *)
    _help
    ;;
esac
