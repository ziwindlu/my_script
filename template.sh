#!/bin/bash

# 帮助{{{
help(){
		echo "Usage: `basename $0`"
		echo "Example: `basename $0`"
}
# }}}
# 初始化{{{
init(){
		# 脚本在发生错误时立即退出。
		set -e 
		#使用未定义的变量时退出。
		set -u 
		# 确保管道中任何命令失败都会导致脚本退出。
		set -o pipefail
		# 检测操作系统是否支持
		check_os_suport
		# 检查依赖
		check_depen
		# 创建日志文件
		if [ ! -f "$LOG_FILE" ]; then
				touch "$LOG_FILE"
		fi
}
# }}}
# 参数解析{{{
get_opts(){
		while getopts "ab:c::" opt; do
				case $opt in
						# a)
								# flag_a=true ;;
						# b)
								#     value_b=$OPTARG ;;
						# c)
								#     if is_option $OPTARG; then
								#         value_c="default"
								#         ((OPTIND--))
								#     else
								#         value_c=$OPTARG
								#     fi
								#     ;;
						*)
								echo "Unknown option"
								exit 1
								;;
				esac
				# 获得没有被解析的内容
				shift $((OPTIND - 1))
		done
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
DEPENS=("ls")
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
		exit 0
}

main(){
		init 
		get_opts "$@"
		run "$@"
}

main "$@"

