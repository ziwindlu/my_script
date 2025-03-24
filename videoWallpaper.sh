#!/bin/bash

# description:
#   一个帮助你设置linux下视频壁纸的脚本, 暂时只支持x11
#   a script to help you set a video wallpaper in linux, only suport x11

# your need: 你得安装以下软件
# ffprobe
# xwinwrap 
# mpv
# bc
# xrandr

# usage
# 	usage: videoWallpaper.sh [is all monitor use same video]

# todo
# [x] auto adapt multi monitor (use xrandr)
# [x] auto configration monitor dpi

# 存放壁纸的根目录
# the video root
videoRoot=~/videoWallpaper

# 一个方法，一看就懂
# get the width / height 
# example input: "640x480"
# example output: 1.33
function getResolution(){
		w=$(echo "$1" | cut -d 'x' -f 1)
		h=$(echo "$1" | cut -d 'x' -f 2)
		echo $(bc <<< "scale=2; $w/$h")
}

# 获取到每个屏幕的长宽，用于设置下面的xwinwrap的参数
# get your screen infomation
allMonitors=($(xrandr | awk '/ connected/ {if ($3 == "primary") print $4; else print $3}'))

# 随机选择一张壁纸
# random a wallpaper video="$videoRoot/"`ls $videoRoot | shuf | head -n 1` 关闭xwinwrap
# kill xwinwrap
pkill xwinwrap

# 遍历所有的显示器挨个设置
# 多个显示器其实可以一键设置，但是俺不想写了，都给我遍历
# set wallpaper in every monitor
for screen in ${allMonitors[@]}; do
		# 重新如果没有参数就随机选择一张壁纸
		# get a new video file
		if ! test -z $1; then
				videoPath="$videoRoot/"`ls $videoRoot | shuf | head -n 1`
		fi
		# 获取视频的长宽
		# get the video width and height
		video_resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $videoPath)
		# echo $screen
		v=$(getResolution $video_resolution)
		s=$(getResolution $(echo $screen | cut -d '+' -f 1))
		# 使用比例相减不知道对不对，就这样用吧
		# a right calculate ?
		if [[ $(bc <<< "$s==$v") == 1 ]]; then
				mpvScale=0
		else
				if [[ $(bc <<< "$s>$v") == 1 ]]; then
						mpvScale=$(bc <<< "$s-$v")				
				else
						mpvScale=$(bc <<< "$v-$s")							
				fi
		fi
		# echo $mpvScale
		# 这么多参数，俺也不太懂
		# $screen是屏幕的长宽和绝对位置 
		# $mpvScale是屏幕长宽比和视频长宽比不一致时的缩放 
		# $videoPath是视频路径
		# set wallpaper
		xwinwrap -g $screen -ni -s -nf -b -un -ov -fdt -argb -- mpv --video-zoom=$mpvScale -wid WID --ao=null --loop=inf --stop-screensaver= "$videoPath" &
done

