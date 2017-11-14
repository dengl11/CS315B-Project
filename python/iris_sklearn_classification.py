############################################################
# Sklearn Decision Tree Classification on Iris 
############################################################

import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier

# param
max_depth = 3

# load data 
iris = load_iris()
X = iris.data
y = iris.target

selected = (y >= 1)
X = X[selected, :]
y = y[selected]


# split train-test
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)

# print(y_train)

# construct estimator
estimator = DecisionTreeClassifier(max_depth=max_depth , random_state=0)

# train
estimator.fit(X_train, y_train)

# [pred_train, pred_test]
predictions = [estimator.predict(x) for x in (X_train, X_test)]

# [acc_train, acc_test]
accuracys = [accuracy_score(p, y) for (p, y) in zip(predictions, (y_train, y_test))]

print("------------------- Sklearn Decision Tree -------------------")
print("Train Accuracy: {:.2f}".format(accuracys[0]))
print("Test Accuracy : {:.2f}".format(accuracys[1]))
