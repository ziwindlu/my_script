#!/bin/bash
# author: ziwindlu

# 帮助{{{
help(){
	echo "Usage: `basename $0` [-A password] [-P socks5_port] ssh_coonection"
	echo "Example: `basename $0` -A 123123 -P 1080 root@192.168.2.100"
	echo "Config: "
	echo "	config path: $(dirname $0)/.$(basename $0).conf"
	echo "Example Config:"
	echo "# config start"
	echo "DEFAULT_PASS=\"123456\""
	echo "DEFAULT_PORT=\"1080\""
	echo "DEFAULT_CONNECT=\"root@192.168.2.100 -p 10022\""
	echo "# config end"

}
# }}}
# 初始化{{{
init(){
	# 脚本在发生错误时立即退出。
	set -e 
	# 确保管道中任何命令失败都会导致脚本退出。
	set -o pipefail
	# 检测操作系统是否支持
	# check_os_suport
	# 检查依赖
	check_depen
	# 创建日志文件
	if [ ! -f "$LOG_FILE" ]; then
		touch "$LOG_FILE"
	fi
	# 加载配置文件
	CONFIG_FILE="$(dirname $0)/.$(basename $0).conf"
	log DEUG $CONFIG_FILE
	if [ -f "$CONFIG_FILE" ];then
		source $CONFIG_FILE
	fi
}
# }}}
# 参数解析{{{
get_opts(){
	# 设置默认值
	pass=$DEFAULT_PASS
	port=$DEFAULT_PORT
	while getopts "A:P:" opt; do
		case $opt in
			A)
				pass=$OPTARG
				;;
			P)
				port=$OPTARG
				;;
			*)
				help
				exit 1
				;;
		esac
	done
	# 处理剩余参数
	shift $((OPTIND - 1))
	other=${@:-$DEFAULT_CONNECT}
}

is_option(){
	[[ $OPTARG == -* ]]
}

#}}}
# 检查操作系统是否支持{{{
check_os_suport(){
	source /etc/os-release
	case $ID in
		centos | ubuntu | debian | kali | arch)
			;;
		*)
			echo "Error: $ID is not supported."
			exit 1
	esac
}
# }}}
# 检测依赖软件包{{{
DEPENS=("ssh" "sshpass")
check_depen(){
	for c in ${DEPENS[@]}; do
		if has_cmd $c ; then
			echo "Error: $c is not installed."
			exit 1
		fi 
	done
}
# }}}
# 是否存在某个命令{{{
has_cmd () {
	[ command -v $1 >/dev/null 2>&1 -gt 0 ]
}
# }}}
# 日志{{{
LOG_FILE="$(dirname $0)/.$(basename $0).log"
log() {
	if [ $# -eq 1 ];then
		local message="$1"
		local level="INFO"
	else
		local level="$1"
		local message="$2"
	fi
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}
# }}}

# 用户定义命令
run(){
	if [[ -z $other || -z $port || -z $other ]]; then
		help
		log ERROR "has empty param, please check."
		exit 1
	fi
	log DEBUG "ssh connect: $other"
	log DEBUG "socks5 port: $port"
	echo -e "please run in terminal:\n"
	echo "export ALL_PROXY=\"socks5://127.0.0.1:$port\"" 
       	echo "export SOCKS5_PROXY=\"socks5://127.0.0.1:$port\""
	echo "export SOCKS_PROXY=\"socks5://127.0.0.1:$port\""
	echo "export http_proxy=\"socks5://127.0.0.1:$port\""
	echo -e "export https_proxy=\"socks5://127.0.0.1:$port\" \n"
	log INFO "try start socks5 proxy"
	sshpass -p $pass ssh -D $port $other
	log INFO "stop socks5 proxy"
	exit 0
}

main(){
	init 
	get_opts "$@"
	run "$@"
}

main "$@"

