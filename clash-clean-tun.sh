#!/bin/bash

exec 1> /dev/null
exec 2> /dev/null

PROXY_TUN_DEVICE_NAME=clash0
PROXY_BYPASS_USER=nobody
PROXY_ROUTE_TABLE=0x233

ip link set dev "$PROXY_TUN_DEVICE_NAME" down
ip tuntap del "$PROXY_TUN_DEVICE_NAME" mode tun

ip route del default dev "$PROXY_TUN_DEVICE_NAME" table "$PROXY_ROUTE_TABLE"

ip rule del lookup "0x162"
ip rule del to 172.16.0.0/12 goto 32766
ip rule del to 224.0.0.0/4 goto 32766
ip rule del to 192.168.0.0/16 goto 32766
ip rule del to 10.0.0.0/8 goto 32766
ip rule del to 127.0.0.0/8 goto 32766
ip rule del uidrange "65534-65535" goto 32766
ip rule del to "172.31.255.253/30" goto 32767

exit 0