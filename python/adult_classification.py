############################################################
# My Decision Tree Classification 
############################################################

import numpy as np

from sklearn.metrics import accuracy_score
from my_decision_tree import *
from datetime import datetime

# param
max_depth = 3

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
    

# X_train, y_train = get_data("../data/adult/adult_train.tsv")
# X_test, y_test = get_data("../data/adult/adult_test.tsv")
# X_train, y_train = get_data("../data/adult/adult_train_small.tsv")
# X_test, y_test = get_data("../data/adult/adult_test_small.tsv")

X_train, y_train = get_data("../data/adult/adult_train_medium.tsv")
X_test, y_test = get_data("../data/adult/adult_test_medium.tsv")
# X_train, y_train = get_data("../data/adult/adult_train_tiny.tsv")
# X_test, y_test = get_data("../data/adult/adult_test_tiny.tsv")

# Tree initialization
my_tree = MyDecisionTree(max_depth = max_depth)

# Train
print("--- Train Start ----")
train_start = datetime.now()
my_tree.train(X_train, y_train)
train_end = datetime.now()
print("--- Train Done ----")

# [pred_train, pred_test]
test_start = datetime.now()
predictions = [my_tree.predict(x) for x in (X_train, X_test)]
test_end = datetime.now()

# [acc_train, acc_test]
my_accuracys = [accuracy_score(p, y) for (p, y) in zip(predictions, (y_train, y_test))]

print("------------------- My Decision Tree -------------------")
print("Training Time: {:.2f} sec".format((train_end - train_start).microseconds/1000))
print("Testing  Time: {:.2f} sec".format((test_end - test_start).microseconds/1000))

print("Train Accuracy: {:.2f}".format(my_accuracys[0]))
print("Test Accuracy : {:.2f}".format(my_accuracys[1]))
