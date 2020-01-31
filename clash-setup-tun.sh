#!/bin/bash

# User            nobody(65534)
# Device          clash0
# Device Address  172.31.255.253/30
# Route Table ID  0x162

/usr/lib/clash/scripts/clash-clean-tun.sh 2>&1 > /dev/null

ip tuntap add "clash0" mode tun user "65534"
ip link set "clash0" up

ip address replace 172.31.255.253/30 dev "clash0"

ip route replace default dev "clash0" table "0x162"

ip rule add lookup "0x162"
ip rule add to 172.16.0.0/12 goto 32766
ip rule add to 224.0.0.0/4 goto 32766
ip rule add to 192.168.0.0/16 goto 32766
ip rule add to 10.0.0.0/8 goto 32766
ip rule add to 127.0.0.0/8 goto 32766
ip rule add uidrange "65534-65535" goto 32766
ip rule add to "172.31.255.253/30" goto 32767     # Prevent broadcast storm