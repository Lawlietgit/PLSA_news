# coding: utf-8

import os
import sys
import time
import logging
import argparse

from shared.log_stuff import setup_logging, shutdown_logging_file
logger = logging.getLogger(__name__)

from shared.spark_utils import init_spark
from word_split._core import run
#from dataprep.dataprep._core import run

def main(args):
    file_handler = setup_logging("word_split")
    sc, spark = init_spark("word_split")
    try:
        run(spark)
        logger.info("finished running word_split program!")
    finally:
        shutdown_logging_file(file_handler)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="word_split args")
    parser.add_argument('input_path', help="Path to input dir", default='/fmacdata/dev/fir/user/qi/hve/snapshots/dataprep/input/')
    parser.add_argument('output_path', help="Path to output dir", default='/fmacdata/dev/fir/user/qi/hve/output/controlled-output/dataprep/')
    args = parser.parse_args()
    logger.info(args)
    c = time.time()
    main(args)
    logger.info("execution took {:.3f} sec.".format(time.time()-c))
