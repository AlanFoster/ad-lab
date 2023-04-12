#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_git
version_added: "0.0.1"
short_description: Git clone or checkout a repository
description:
    - Git clone or checkout a repository
notes:
    - Uses a subset of the options provided by the posix-only 'git' action https://github.com/ansible/ansible/blob/babdec80cc562fec2b4d07132112b75c7b0438ff/lib/ansible/modules/git.py
options:
  repo:
      description:
          - The Git repo to clone
      type: str
      required: true
  dest:
    description:
      - The destination folder for the Git clone/fetch
    required: true
requirements:
- git>=1.7.1 (the command line tool)
author: []
'''

EXAMPLES = '''
  win_git:
    repo: "https://github.com/repo/project"
    dest: "c:/project"
'''
