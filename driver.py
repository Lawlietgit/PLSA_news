#!/usr/bin/env python

import argparse
import logging
import os
import sys
import shared.run_utils as phase2


def main(argv):
    parser = argparse.ArgumentParser(description="PLSA_Financial_News")
    subparsers = parser.add_subparsers(help="actions")

    batch = subparsers.add_parser("run_batch",
        help="generate output file based on batch configuration")
    batch.add_argument("config",
        help="path to batch configuration file")
    batch.set_defaults(func=phase2.run_batch)
    
    # Actually run it
    args = parser.parse_args()
    args.func(args)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
