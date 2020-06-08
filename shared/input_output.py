import os
import logging
import pandas as pd

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

def read_csv_spark(spark, path):
    default={'sep': ',',
             'header': 'true',
             'inferSchema':'false',
             'escape': "\"",
             'quote': "\"",
             'encoding': 'utf-8',
             'mode':'DROPMALFORMED'}
    df = spark.read.csv(path, **default)
    logger.info('Reading {} rows and {} cols from {}.'
                .format(df.count(), len(df.columns), path))
    return df

def write_parquet_spark(df, path, coalesce=False):
    logger.info("Writing {} rows and {} cols to {}"
                .format(df.count(), len(df.columns), path))
    df.cache()
    if coalesce:
        df.coalesce(1).write.parquet(path, mode='OVERWRITE')
    else:
        df.write.parquet(path, mode='OVERWRITE')
    df.unpersist()

def read_parquet_spark(spark, path):
    """Read parquet by Spark from given file path"""
    df = spark.read.parquet(path)
    logger.info('Reading {} rows and {} cols from {}.'
                .format(df.count(), len(df.columns), path))
    return df

def write_csv_spark(df, path, coalesce=False):
    logger.info("Writing {} rows and {} cols to {}"
                .format(df.count(), len(df.columns), path))
    default={'sep': ',',
             'header': 'true',
             'escape': "\"",
             'quote': "\"",
             'mode':'overwrite'}
    df.cache()
    if coalesce:
        df.coalesce(1).write.csv(path, **default)
    else:
        df.write.csv(path, **default)
    df.unpersist()
