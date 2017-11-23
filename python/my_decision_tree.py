############################################################
# My Decision Tree 
############################################################

import numpy as np


def gini(arr):
    """return gini impurity value of a binary array 
    Return: 
    """
    n = len(arr)
    frac_1 = sum(arr)/n
    frac = [1-frac_1, frac_1]
    return 1 - sum(x ** 2 for x in frac)


class DTNode(object):

    """decision tree node"""
    X = None
    y = None 
    gini = None 
    n = None # number of porints on current node 
    label = None # for leaf node only, label of current node: 0 | 1
    depth = 0
    left = None
    right = None

    split_feature = None
    split_val = None 

    def __init__(self, depth, X, y):
        """
        Args:
        """
        self.depth = depth 
        self.X = X
        self.y = y
        self.n = len(y)
        self.gini = gini(y)
        self.num_feature = X.shape[1]
        
    def __str__(self):
        me = "{} Depth {} -> ".format('\t'*self.depth, self.depth) 
        if self.label is not None: me += "[{}]".format(self.label)
        else :
            me += "Split by Feature {} at {} ".format(self.split_feature, self.split_val)
        me  += " (Gini = {:.2f}) | # Nodes: {}".format(self.gini, self.n)
        ans = [me]
        if self.left: ans.append(str(self.left))
        if self.right: ans.append(str(self.right))
        return "\n".join(ans)


    def split_by_feature(self, feature):
        """return resulting (gini impurity, split_val) if splitting by feature
        Args:
            feature: 

        Return: 
        """
        # sort by feature values 
        pairs = sorted(zip(self.X[:, feature], self.y)) # [(feature_val, label)]
        feature_vals = [x[0] for x in pairs]
        labels = [x[1] for x in pairs]
        lowest_gini = self.gini 
        split_val, reverse = None, None 

        for i, (feature_val, label) in enumerate(pairs[:-1]):
            left = labels[:i+1]
            right = labels[i+1:]
            curr_gini = len(left) * gini(left) + len(right) * gini(right)
            curr_gini /= self.n 
            # print("{}->{}".format(feature_val, curr_gini))
            if curr_gini < lowest_gini:
                lowest_gini = curr_gini 
                split_val = feature_val 

        if lowest_gini == self.gini: return None 

        return (lowest_gini, split_val) 

        

    def best_split(self):
        """find best split on current data 
        Return: 
        """
        best_gini = float('inf')
        split_val, feature = None, None 
        for i in range(self.num_feature):
            curr = self.split_by_feature(i)
            if not curr: continue
            if curr[0] < best_gini:
                best_gini = curr[0]
                split_val = curr[1]
                feature = i 
        return feature, split_val 


    def split(self):
        """split into two sub-trees 
        Return: True if can still grow Else False 
        """
        (feature, split_val) = self.best_split()
        # print("Split: {} | split_val = {}".format(feature, split_val))
        if feature is None: return False 
        self.split_feature = feature
        self.split_val = split_val 
        left = self.X[:, feature] <= split_val 
        right = self.X[:, feature] > split_val 
        # print("\tleft = {} | right = {}".format(left, right))
        self.left = DTNode(self.depth + 1, self.X[left,:], self.y[left])
        self.right = DTNode(self.depth + 1, self.X[right,:], self.y[right])
        return True 


    def can_grow(self, max_depth):
        """
        Args:
            max_depth: 

        Return: 
        """
        if self.depth >= max_depth: return False 
        if self.gini == 0: return False
        return True 

    
    def set_label(self):
        """set label of current node 
        Return: 
        """
        self.label = int(sum(self.y) > self.n/2 )


    def grow(self, max_depth):
        """grow current node up to max_depth 
        Args:
            max_depth: 

        Return: 
        """
        if self.can_grow(max_depth) and self.split(): 
            self.left.grow(max_depth)
            self.right.grow(max_depth)
        else:
            self.set_label()


class MyDecisionTree(object):

    """decision tree instance"""

    root = None 

    def __init__(self, max_depth = 3):
        """
        Kwargs:
            max_depth: 
        """
        self._max_depth = max_depth

    def __str__(self):
        return str(self.root)

    def train(self, X, y):
        """train on (X, y)
        Args:
            X: np matrix 
            y: np array 

        Return: 
        """
        self._num_feature = X.shape[1]
        self.root = DTNode(0, X, y)
        self.root.grow(self._max_depth)

    def predict_point(self, p):
        """predict a certain point
        Input:
                p - np array of features 
        Return: 
        """
        curr_node = self.root 
        while curr_node.label is None: # not leaf node
            feature = curr_node.split_feature 
            split_val = curr_node.split_val 
            # print("split_val = {}".format(split_val))
            if p[feature] <= split_val: curr_node = curr_node.left
            else: curr_node = curr_node.right
        return curr_node.label 


    def predict(self, X):
        """generate predictions for X
        Args:
            X: 

        Return: 
        """
        return [self.predict_point(x) for x in X]
        
