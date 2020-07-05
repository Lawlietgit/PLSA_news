# coding: utf-8

import os, sys
import pandas as pd
import numpy as np
import logging
import time
from shared.input_output import (read_csv_spark, write_parquet_spark,
                                 read_parquet_spark, write_csv_spark)
from bs4 import BeautifulSoup
import hanlp
import re
from pyspark.sql.types import StringType
from pyspark.sql.functions import udf, col
import codecs

logger = logging.getLogger(__name__)


tokenizer = hanlp.load('PKU_NAME_MERGED_SIX_MONTHS_CONVSEG')
#tokenizer = hanlp.load('CTB6_CONVSEG')

remove_set = set(["?", ":", ":", "万得", "通讯社", "报道", "年", "月", "日", "年月日", "日晚", "年月",
                  "月日", "新浪财"])
lines = codecs.open('/home/hadoop/PLSA_news/data/chinese_stopwords.txt', 'r', 'utf-8').readlines()
stopwords = set()
for line in lines:
    words = line.replace('\n','').split(',')
    words = [re.sub(r'\s+', '', w) for w in words if w!='']
    stopwords = stopwords.union(set(words))
kill_set = remove_set.union(stopwords)

def get_text(c, html=True):
    if html:
        soup = BeautifulSoup(c, 'html.parser')
        text = soup.getText()
    else:
        text = c
    p = r"[\s+\.\!\/_,$%^*(+\"\']+|[+——！，？?、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]"
    words = tokenizer(re.sub(p, '', text))
    words = [w for w in words if w not in kill_set] 
    return ' '.join(words).strip()
    

getText_udf = udf(lambda x: get_text(x), StringType())
getTitle_udf = udf(lambda x: get_text(x, html=False), StringType())

def run(spark=None):
    path = 's3://qi-plsa-test/data/FINANCIALNEWS_sample.csv'
    df = read_csv_spark(spark, path)
    df = df.filter(col('WINDCODES').isNotNull())
    df.show()
    df = df.withColumn("clean_text", getText_udf(df.CONTENT))
    df = df.withColumn("clean_title", getTitle_udf(df.TITLE))
    df = df.select(['OBJECT_ID', 'WINDCODES', 'clean_title', 'clean_text'])
    df.show()
    print('hanlp finished!')
    print(df.count())
    df.printSchema()
    outpath = 's3://qi-plsa-test/output/word_split_sample.parquet'
    write_parquet_spark(df, outpath, coalesce=True)
    df = read_parquet_spark(spark, outpath)
    #outpath = 'word_split_sample.csv'
    #write_csv_spark(df, outpath)
    #df = read_csv_spark(spark, outpath)
    df.printSchema()
    df.show()
