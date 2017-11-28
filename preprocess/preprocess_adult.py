############################################################
# Preprocessor for Adult Dataset 
############################################################

import os 
import sys
sys.path.append(".")
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.datasets import *
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier
from lib import DataframePreprocessor  
from util import * 


# param 
dataset_name = "adult"
train_ratio = 0.7

# output 
data_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "../data/{}/".format(dataset_name))
train_output = os.path.join(data_dir, "adult_train.tsv")
test_output = os.path.join(data_dir, "adult_test.tsv")


original_csv = os.path.join(data_dir, "original/adult.csv")

df_processor = DataframePreprocessor.init_from_file(original_csv)

df_processor.remove_cols(["workclass", "education", "marital-status", "occupation", "relationship", "race", "native-country", "fnlwgt"], kind="name")

df_processor.transform_category("gender", {"Male": 1, "Female": 0})
df_processor.transform_category("income", {">50K": 1, "<=50K": 0})

columns = df_processor.column_list()
tgt_ind = columns.index("income")
columns = ["income"] + columns[:tgt_ind] + columns[tgt_ind + 1 :]

df_processor.reorder_columns(columns)
df_processor.shuffle_rows()
df = df_processor.get_dataframe()

print(df_processor.peek_head() )
df = df_processor.get_dataframe()
n_row, n_col = (df.shape)

##################################################
num_train = int(n_row * train_ratio )

train_mat = df.values[:num_train, :]
save_matrix(train_output, train_mat)

test_mat = df.values[num_train:, :]
save_matrix(test_output, test_mat)
