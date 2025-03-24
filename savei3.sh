#!/bin/bash

# 帮助{{{
help(){
		echo "Usage: `basename $0` <workspace_num>"
		echo "Example: `basename $0` 1"
		exit 0
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
		# 参数检查
		if [[ "$#" -ne 1 ]]; then
				help
		fi
		user_input="$1"
}

#}}}
# 检查操作系统是否支持{{{
check_os_suport(){
		source /etc/os-release
		case $ID in
				centos | ubuntu | debian | kali | arch)
						;;
				*)
						log ERROR "Error: $ID is not supported."
						exit 1
		esac
}
# }}}
# 检测依赖软件包{{{
# <++>
DEPENS=("jq")
check_depen(){
		for c in ${DEPENS[@]}; do
				if has_cmd $c ; then
						log ERROR "Error: $c is not installed."
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

# 校验目录
check_dir(){
		for d in $@; do
				[[ -e `dirname $d` ]] || ( mkdir -p `dirname $d` && log INFO "mkdir `dirname $d`" ) 
		done
}

is_num(){
		[[ $1 =~ ^[0-9]+$ ]] && return 0 || return 1
}

get_output(){
		if is_num "$1"; then
				workspace_output=$(i3-msg -t get_workspaces | jq -r ".[] | select(.num==$1).output")
		else
				workspace_output=$(i3-msg -t get_workspaces | jq --arg name "$1" -r '.[] | select(.name==$name).output')
		fi
}

get_workspace_name(){
		if is_num "$1"; then
				workspace_name=$(i3-msg -t get_workspaces | jq -r ".[] | select(.num==$1).name")
		else
				workspace_name="$1"
		fi
}

main(){
		# 初始化
		init 
		get_opts "$@"
		# 设置配置目录
		i3_config_dir="$HOME/.config/i3"
		shell="$i3_config_dir/sh/$user_input.sh"
		json="$i3_config_dir/json/$user_input.json"
		check_dir $shell $json 
		# 获取 workspace 名称和显示器
		get_workspace_name "$user_input"
		get_output "$user_input"
		echo workspace_name=$workspace_name
		echo workspace_output=$workspace_output
		# 备份旧的 JSON 文件
		# [[ -e "$json" ]] && mv "$json" "$json.bac"
		# 备份旧的 shell 脚本
		# [[ -e "$shell" ]] && mv "$shell" "$shell.bac"
		# 生成新的 JSON 布局文件
		i3-save-tree --workspace "$user_input" > "$json.tmp"
		# 清理 JSON 文件中的无用信息
		sed -i 's|^\(\s*\)// "|\1"|g; /^\s*\/\//d' "$json.tmp"
		jq 'del(.. | .title?, .window_role?)' "$json.tmp" > "$json"
		rm "$json.tmp"
		# 生成恢复脚本
		cat <<EOF > "$shell"
#!/bin/bash
i3-msg "workspace \"$workspace_name\"; append_layout $json"
i3-msg "move workspace to output $workspace_output"
# This is your application, you may modify them
EOF
		# 获取应用名，并附加到脚本
		apps=$(jq -r '.. | .class? //empty' "$json" | sed 's/\\//g; s/\^//g; s/\$//g; s/\"//g' | sed -r 's/(^| )(.)/\1\L\2/g')
		for app in $apps; do
				echo "$app &" >> "$shell"
		done
		# 设置执行权限
		chmod +x "$shell"
		log INFO "The restore script has been generated: $shell"
		log INFO "The restore json has been generated: $json"
		log INFO "Do you want to edit the shell script? (y/n)"
		read -r confirm
		if [[ -z $confirm || "$confirm" == "y" || "$confirm" == "Y" ]]; then
				vim "$shell"
		fi
		exit 0
}

main "$@"

