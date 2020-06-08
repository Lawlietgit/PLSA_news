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

logger = logging.getLogger(__name__)


def get_text(c, html=True):
    if html:
        soup = BeautifulSoup(c, 'html.parser')
        text = soup.getText()
    else:
        text = c
    p = r"[\s+\.\!\/_,$%^*(+\"\']+|[+——！，？?、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]"
    tokenizer = hanlp.load('PKU_NAME_MERGED_SIX_MONTHS_CONVSEG')
    return ' '.join(tokenizer(re.sub(p, '', text))).strip()
    

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
    print(df.count())
    df.printSchema()
#    outpath = 's3://qi-plsa-test/output/word_split_sample.parquet'
#    write_parquet_spark(df, outpath, coalesce=True)
#    df = read_parquet_spark(spark, outpath)
    outpath = 'word_split_sample.csv'
    write_csv_spark(df, outpath)
    df = read_csv_spark(spark, outpath)
    df.printSchema()
    df.show()
    


#df = df.set_index('OBJECT_ID')
#
#
#def get_text(c):
#    soup = BeautifulSoup(c, 'html.parser')
#    return soup.getText()
#    #return re.sub("[\s+\.\!\/_,$%^*(+\"\']+|[+——！？、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]", "",t)
#
#
#p = r"[\s+\.\!\/_,$%^*(+\"\']+|[+——！？、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]"
#df['clean_text'] = df['CONTENT'].apply(lambda x: get_text(x))
#df = df[~df.clean_text.str.contains('您没有浏览')]
#df.clean_text = df.clean_text.apply(lambda x: re.sub(p,'',x))
#df.TITLE = df.TITLE.apply(lambda x: re.sub(p,'', x))
#
#
#print(df.columns)
#print(df.head(5))
#
#df = df[['TITLE', 'WINDCODES', 'clean_text']]
#tokenizer = hanlp.load('PKU_NAME_MERGED_SIX_MONTHS_CONVSEG')
##sen_splitter = hanlp.utils.rules.split_sentence
#
#for i in range(len(df)):
#    idx = df.index[i]
#    a = tokenizer(df.TITLE.values.tolist()[i])
#    b = tokenizer(df.clean_text.values.tolist()[i])
#    t = np.array([idx, a, b]).reshape(1, -1)
#    t_df = pd.DataFrame(t, columns=['OBJECT_ID','title_token', 'text_token'])
#    if i == 0:
#        t_df.to_csv('token.csv', mode='w', header=True, index=False)
#    else:
#        t_df.to_csv('token.csv', mode='a', header=False, index=False)
#
