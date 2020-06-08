"""Util functions used to run shell commands
"""
import os
import shutil
import subprocess
import yaml
import functools

def join(loader, node):
    seq = loader.construct_sequence(node)
    return ''.join([str(i) for i in seq])

## register the tag handler
yaml.add_constructor('!join', join)


def run_batch(args):
    """"Entry point to run phase 2 modules"""
    cfg = load_yaml(args.config)
    if not os.path.exists(cfg['main']['outdir']) and not cfg['main']['outdir'].startswith('s3://'):
        os.makedirs(cfg['main']['outdir'])
    run_modules(cfg['modules'])

def sh_run(bin, args, expected_ret=0, properties=None, config=None, cwd=None):
    """
    Calls shell script, which in turn runs python script
    """

    # Need to add environment variables
    cmd_env = os.environ.copy()
    cmd = bin.split() + args
    print(cmd)
    p = subprocess.Popen(cmd, env=cmd_env, cwd=cwd)
    p.communicate()
    return p.returncode == expected_ret

def run_modules(cfg):
    """Run a set of modules defined by config cfg
    """
    cwd = os.getcwd()
    for steps in cfg:
        bin = cfg[steps]['cmd']
        args = cfg[steps]['args']
        if cfg[steps]['run']:
            res = sh_run(bin, args, cwd=cwd)
        else:
            print("Skip step: {}".format(steps))
            res = True
        if not res:
            break

def load_yaml(fpath):
    """Loads a yaml file from disk"""
    with open(fpath) as fh:
        return yaml.load(fh, Loader=yaml.Loader)
      

def relpath(*args):
    """Returns an absolute path relative to this file"""
    return os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        *args)


class RelPath(object):
    """Small helper object for returning paths relative a base"""

    def __init__(self, base):
        self._base = base

    def path(self, *args):
        return os.path.join(self._base, *args)
