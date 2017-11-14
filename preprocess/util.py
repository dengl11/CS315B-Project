############################################################
# Utility Function for Preprocessing
############################################################

import numpy as np

def save_matrix(path, matrix, delimiter='\t'):
    """save a matrix to file, conforming to the desired format 
    Args:
        path: 
        matrix: 

    Return: 
    """
    with open(path, 'w') as f:
        row, col = matrix.shape
        col -= 1 # the 1st column is the label 
        f.write("{}\n".format(row))
        f.write("{}\n".format(col))
    with open(path, 'ab') as f:
        np.savetxt(f, matrix, delimiter=delimiter, fmt='%.2g')
