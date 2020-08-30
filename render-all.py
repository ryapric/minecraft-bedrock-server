#!/usr/bin/env python3

"""
This script is the workhorse that safely fills all of the dynamic values across
all files in this repo.
"""

from jinja2 import Template
import os
import re
import sys
import yaml

# Allow users to pass in custom config files via the 'CONFIG' env var (handled
# by the Makefile)
config_file = os.environ.get('CONFIG', 'config.yaml')

# Load user config
with open(config_file) as f:
    config = yaml.safe_load(f.read())

# Define any helper functions you might want to pass to templates to use
def cat_file(filename):
    with open(filename) as f:
        x = f.read()
    return x
config['cat_file'] = cat_file

# File to render is passed as arg 1 on CLI
argfile = sys.argv[1]
print(f'Rendering {argfile}')

# Please stick to the format, folks, I'm only one guy over here
if '_jinja' not in argfile:
    raise Exception('You may only pass in files containing `_jinja` for rendering. Aborting.')

# Read the file to render
with open(argfile) as f:
    template = f.read()

# Stick a do-not-edit header on top
header = """\
####################################################################
# !!! DO NOT EDIT BY HAND. Created by the `render-all.py` file !!! #
####################################################################

"""
if '.json' not in argfile:
    template = header + template

# Render Jinja template using global config dict
jinja_template = Template(template)
rendered_template = jinja_template.render(config = config)

# Write back out!
with open(re.sub('_jinja', '', argfile), 'w') as f:
    f.write(rendered_template)
