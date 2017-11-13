############################################################
# Generator for Iris Dataset for Regent 
############################################################

import os 
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier

# param
data_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "../data/iris/")
train_output = os.path.join(data_dir, "iris_train.tsv")
test_output = os.path.join(data_dir, "iris_test.tsv")

# load data 
iris = load_iris()
X = iris.data
y = iris.target

# split train-test
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)

# save train
train_mat = np.column_stack((y_train, X_train))
np.savetxt(train_output, train_mat, delimiter='\t', fmt='%.2g')

# save test 
test_mat = np.column_stack((y_test, X_test))
np.savetxt(test_output, test_mat, delimiter='\t', fmt='%.2g')