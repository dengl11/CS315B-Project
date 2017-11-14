############################################################
# My Decision Tree Classification on Iris 
############################################################

import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score
from my_decision_tree import *

# param
max_depth = 3

# load data 
iris = load_iris()
X = iris.data
y = iris.target

selected = (y >= 1)
X = X[selected, :]
y = y[selected]
miny = min(y)
maxy = max(y)
y[y == miny] = 0
y[y == maxy] = 1

# split train-test
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)

# Tree initialization
my_tree = MyDecisionTree(max_depth = max_depth)

# Train
my_tree.train(X_train, y_train)

# [pred_train, pred_test]
predictions = [my_tree.predict(x) for x in (X_train, X_test)]

# [acc_train, acc_test]
my_accuracys = [accuracy_score(p, y) for (p, y) in zip(predictions, (y_train, y_test))]

print("------------------- My Decision Tree -------------------")
print("Train Accuracy: {:.2f}".format(my_accuracys[0]))
print("Test Accuracy : {:.2f}".format(my_accuracys[1]))
