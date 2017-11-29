############################################################
# My Decision Tree Classification 
############################################################

import numpy as np

from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier
from my_decision_tree import *

# param
max_depth = 3
# max_depth = 6

def get_data(input):
    """return (X, y) for input 
    Args:
        input: 

    Return: 
    """
    mat = np.loadtxt(input, skiprows=2)
    y = mat[:, 0].astype(int)
    X = mat[:, 1:].astype(np.float)
    return (X, y)
    

X_train, y_train = get_data("../data/adult/adult_train_tiny.tsv")
X_test, y_test = get_data("../data/adult/adult_test_tiny.tsv")
# X_train, y_train = get_data("../data/adult/adult_train.tsv")
# X_test, y_test = get_data("../data/adult/adult_test.tsv")

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
