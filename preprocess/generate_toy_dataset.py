############################################################
# Generator for Toy Dataset from Sklearn for Regent 
############################################################

import os 
import sys
sys.path.append(".")
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.datasets import *
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier

from util import * 


# param 
dataset_name = "iris"
dataset_name = "cancer"

# output 
data_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "../data/{}/".format(dataset_name))

train_output = os.path.join(data_dir, "{}_train.tsv".format(dataset_name))
test_output = os.path.join(data_dir,  "{}_test.tsv".format(dataset_name))

# load data 
if dataset_name == "iris":
    dataset = load_iris()
elif dataset_name == "cancer":
    dataset = load_breast_cancer()

X = dataset.data
y = dataset.target

###### filter for iris: only keep 2 classes ######
selected = (y >= 1)
X = X[selected, :]
y = y[selected]
miny = min(y)
maxy = max(y)
y[y == miny] = 0
y[y == maxy] = 1

##################################################
# split train-test
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)

# save train
train_mat = np.column_stack((y_train, X_train))
save_matrix(train_output, train_mat)

# save test 
test_mat = np.column_stack((y_test, X_test))
save_matrix(test_output, test_mat)
