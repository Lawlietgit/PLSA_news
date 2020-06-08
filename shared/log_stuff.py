import sys
import os
import logging
import datetime

console_logging_level = logging.INFO
file_logging_level = logging.INFO

pyspark_log = logging.getLogger('pyspark').setLevel(logging.INFO)
py4j_logger = logging.getLogger("py4j").setLevel(logging.INFO)


def setup_logging(fname, timesuffix=True):
    LOG_FMT = '%(asctime)s %(levelname)s %(name)s %(message)s'
    formatter = logging.Formatter(LOG_FMT)
    root_logger = logging.getLogger('')
    root_logger.setLevel(logging.INFO)

    ch_handler = logging.StreamHandler()
    ch_handler.setLevel(console_logging_level)
    ch_handler.setFormatter(formatter)
    root_logger.addHandler(ch_handler)

    if fname:
        if timesuffix:
            fname = fname.split('.log')[0]
            fname = 'logs/{}_{}.log'.format(fname, datetime.datetime.now().strftime('%Y%m%d-%H:%M'))
            dir = os.path.dirname(fname)
            if not os.path.exists(dir):
                os.makedirs(dir)
            if not os.path.isdir(dir):
                raise Exception('{} is a file not a directory!!!'.format(dir))
        file_handler = logging.FileHandler(fname, mode='w')
        file_handler.setLevel(file_logging_level)
        file_handler.setFormatter(formatter)
        root_logger.addHandler(file_handler)
    else:
        file_handler = None

    return file_handler

def shutdown_logging_file(file_handler):
    if file_handler:
        logging.getLogger('').removeHandler(file_handler)
        file_handler.flush()
        file_handler.close()
