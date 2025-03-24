#!/bin/python

# logseq导出markdown到hexo的脚本
# 导出功能、部署功能、本地启动

import argparse
import os
import sys

parser = argparse.ArgumentParser(description='结合博客中目录中的logseq-export-markdown脚本快速导出或同步到github')
parser.add_argument('options', help='export <blog> <logseq-export-markdown -f argument>\n' +
                                    'sync <blog>\n' +
                                    'upload <blog>\n' +
                                    'start <blog>\n' +
                                    'list')
parser.add_argument('other', nargs="*")


class Blog:
    def __init__(self, blog_name, blog_path):
        self.blog_path = blog_path
        self.blog_name = blog_name


blogs_config = {
    'myblog': Blog('myblog', '~/git/myblog')
}


def export(path, file_name):
    print(f"正在导出{file_name}")
    os.system(f'cd {os.path.expanduser(path)} && ./logseq-export.sh {file_name}')
    print("导出完成")


def sync(path):
    print(f"正在同步{path}")
    os.system(f'cd {os.path.expanduser(path)} && ./sync2Git')
    print("同步成功")


def export_blog(blog_name: str, export_names: list):
    if len(export_names) == 0:
        return
    for kk, vv in blogs_config.items():
        if blog_name == kk or blog_name == 'all':
            # 导出操作
            for name in export_names:
                export(vv.blog_path, name)


def sync_blog(blog_names: list):
    for b in blog_names:
        if b in blogs_config:
            sync(blogs_config.get(b).blog_path)
        else:
            print(f'{b} not found')


def start_server(path):
    os.system(f'cd {os.path.expanduser(path)} && ./start')


if __name__ == '__main__':
    args = parser.parse_args()
    if args.options == 'start':
        if len(args.other) == 0:
            sys.exit(0)
        else:
            start_server(blogs_config.get(args.other[0]).blog_path)
    if args.options == 'sync':
        # 进行同步操作
        if len(args.other) == 0 or 'all' in args.other:
            # 同步所有
            sync_blog(list(blogs_config.keys()))
        else:
            # 仅同步指定的
            sync_blog(args.other)
    elif args.options == 'upload':
        if len(args.other) == 1:
            export_blog('all', args.other[:])
            for kk, vvv in blogs_config.items():
                sync(vvv.blog_path)
        elif len(args.other) > 1:
            if args.other[0] in blogs_config:
                export_blog(args.other[0], args.other[1:])
                sync(blogs_config.get(args.other[0]).blog_path)
        else:
            sys.exit(0)
    elif args.options == 'list':
        for k, v in blogs_config.items():
            print(f"{k}:{v.blog_path}")
    elif args.options == 'export':
        if len(args.other) > 1:
            export_blog(args.other[0], args.other[1:])
        elif len(args.other) == 1 and args.other[0] not in blogs_config:
            export_blog('all', args.other[:])
        else:
            print("please select a post")

