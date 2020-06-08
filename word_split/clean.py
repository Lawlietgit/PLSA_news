import os, sys
import pandas as pd
import numpy as np
import logging
import time
from input_output import read_csv, write_csv
from utils import get_df_info, get_current_time
from bs4 import BeautifulSoup
import hanlp
import re

logger = logging.getLogger(__name__)

if not os.path.exists('./logs'):
    os.mkdir('./logs')


current_time = get_current_time()
f_hdlr = logging.FileHandler('./logs/{}.log'.format(current_time))
fmt = '%(asctime)s [%(levelname)s]: %(name)s - %(message)s'
hdlr = [f_hdlr, logging.StreamHandler()]
logging.basicConfig(level=logging.DEBUG, format=fmt, handlers=hdlr)

path = './data/FINANCIALNEWS_sample.csv'
df = read_csv(path)

df = df.set_index('OBJECT_ID')


def get_text(c):
    soup = BeautifulSoup(c, 'html.parser')
    return soup.getText()
    #return re.sub("[\s+\.\!\/_,$%^*(+\"\']+|[+——！？、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]", "",t)


p = r"[\s+\.\!\/_,$%^*(+\"\']+|[+——！？、~@#￥%……&*（）【】《》℃丨“”(a-z)(0-9)(A-Z)：-]"
df['clean_text'] = df['CONTENT'].apply(lambda x: get_text(x))
df = df[~df.clean_text.str.contains('您没有浏览')]
df.clean_text = df.clean_text.apply(lambda x: re.sub(p,'',x))
df.TITLE = df.TITLE.apply(lambda x: re.sub(p,'', x))


print(df.columns)
print(df.head(5))

df = df[['TITLE', 'WINDCODES', 'clean_text']]
tokenizer = hanlp.load('PKU_NAME_MERGED_SIX_MONTHS_CONVSEG')
#sen_splitter = hanlp.utils.rules.split_sentence

for i in range(len(df)):
    idx = df.index[i]
    a = tokenizer(df.TITLE.values.tolist()[i])
    b = tokenizer(df.clean_text.values.tolist()[i])
    t = np.array([idx, a, b]).reshape(1, -1)
    t_df = pd.DataFrame(t, columns=['OBJECT_ID','title_token', 'text_token'])
    if i == 0:
        t_df.to_csv('token.csv', mode='w', header=True, index=False)
    else:
        t_df.to_csv('token.csv', mode='a', header=False, index=False)

