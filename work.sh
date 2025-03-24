#!/bin/bash

iLoveWork=1
# 本地共享主机的ip
shareVpn="192.168.48.53"
# 虚拟机的ip
localShareVpn="192.168.122.131"
intranet="192.168.2.0"
set -e
sudo route del -net $intranet/24

# 指定使用shareVpn
if ! test -z $1 ;then
		echo "force use shareVpn"
		sudo route add -net $intranet/24 gw "$shareVpn"
		exit 0
fi

# 获取当前日期的星期几
weekend=$(date +%u)

# 判断是否为工作日（星期一至星期五）
if [ $iLoveWork -eq 1 ] || ([ $weekend -gt 0 ] && [ $weekend -lt 6 ]); then
		# 正常逻辑
		ping "$shareVpn" -c 5
		if [[ $? -eq 0 ]]; then
				echo "use shareVpn"
				sudo route add -net $intranet/24 gw "$shareVpn"
		else 
				echo "use localShareVpn"
				sudo virsh start win7-vpn
				sudo route add -net $intranet/24 gw "$localShareVpn"
		fi
		echo "work harder"
else
		echo "enjoy weekend"
fi

