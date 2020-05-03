import os
import logging
import pandas as pd
from utils import touch_dir, get_current_time

logger = logging.getLogger(__name__)

def read_csv(path):
    df = pd.read_csv(path)
    logger.info("Read {} rows and {} cols from {}."
                .format(len(df), df.shape[1], path))
    return df

def write_csv(df, path):
    logger.info("Write {} rows and {} cols to {}."
                .format(len(df), df.shape[1], path))
    df.to_csv(path, index=False)
