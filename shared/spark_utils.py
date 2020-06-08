import logging

from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession

def init_spark(app_name=''):
    app_name = "pyspark-{}".format(app_name)
    logging.info('Creating PySpark application {}'.format(app_name))
    conf = (SparkConf().
            setAppName(app_name)
#               .set("spark.driver.maxResultSize", "10g")
            .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
#               .set("spark.sql.shuffle.partitions", 12)
#               .set("spark.default.parallelism", 12)
            )
    sc = SparkContext(conf=conf)
    # reduce logging
    reduce_spark_logging(sc)
    spark = SparkSession(sc)
    logging.info(sc._conf.getAll())
    return sc, spark

def clear_shuffle_files(sc, spark):
    # Apparently, needed to trigger a GC to get Spark to clear the shuffle
    # files: https://forums.databricks.com/questions/277/how-do-i-avoid-the-no-space-left-on-device-error.html
    sc._jvm.System.gc()
    spark.catalog.clearCache()


def reduce_spark_logging(sc):
    logger = sc._jvm.org.apache.log4j
    logger.LogManager.getRootLogger().setLevel(logger.Level.WARN)
