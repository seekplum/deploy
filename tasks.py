#!/usr/bin/env python
# -*- coding: utf-8 -*-

from invoke import task


@task
def check(ctx):
    cmd = "find . -name '*.yml' -exec ansible-playbook -v --syntax-check {} +"
    ctx.run(cmd, echo=True)
