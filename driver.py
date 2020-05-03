import os, sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import logging
import time
import pickle as pkl
from input_output import read_csv, write_csv
from utils import get_df_info, get_current_time

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

print(df.head(10))
get_df_info(df)
