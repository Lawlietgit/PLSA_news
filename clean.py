import os, sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import logging
import time
from input_output import read_csv, write_csv
from utils import get_df_info, get_current_time
from bs4 import BeautifulSoup
import codecs
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.pipeline import Pipeline
import hanlp

logging.getLogger('matplotlib').setLevel(logging.ERROR)

logger = logging.getLogger(__name__)

if not os.path.exists('./logs'):
    os.mkdir('./logs')


current_time = get_current_time()
f_hdlr = logging.FileHandler('./logs/{}.log'.format(current_time))
fmt = '%(asctime)s [%(levelname)s]: %(name)s - %(message)s'
hdlr = [f_hdlr, logging.StreamHandler()]
logging.basicConfig(level=logging.DEBUG, format=fmt, handlers=hdlr)

np.random.seed(42)

path = './data/FINANCIALNEWS_sample.csv'
df = read_csv(path)

df = df.set_index('OBJECT_ID')


def get_text(c):
    soup = BeautifulSoup(c, 'html.parser')
    return soup.getText()


df['clean_text'] = df['CONTENT'].apply(lambda x: get_text(x))

df = df[~df.clean_text.str.contains('您没有浏览')]

print(df.columns)

df = df[['TITLE', 'WINDCODES', 'clean_text']]
tokenizer = hanlp.load('PKU_NAME_MERGED_SIX_MONTHS_CONVSEG')
#sen_splitter = hanlp.utils.rules.split_sentence
#for i in range(len(df)):
#    print(i)
#    print(tokenizer(df.TITLE.values.tolist()[i]))
#    print(tokenizer(df.clean_text.values.tolist()[i]))

df['title_tokens'] = tokenizer(df.TITLE.values.tolist())
df['text_tokens'] = tokenizer(df.clean_text.values.tolist())
df.to_csv('token.csv')

