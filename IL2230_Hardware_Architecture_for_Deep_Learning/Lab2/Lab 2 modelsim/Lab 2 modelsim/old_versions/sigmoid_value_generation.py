'''
@File    :   sigmoid_value_generation.py
@Time    :   2023/11/24 09:46:47
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   k337364@gmail.com
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
'''


import numpy as np
import matplotlib.pyplot as plt

n = 10
x = range(-6 * n, 6 * n)
y = []

def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def to_n_wide_bin(x, n=8):
    # Ensure that x is in the range [-2^(n-1), 2^(n-1)-1]
    x = max(-(2**(n-1)), min(x, 2**(n-1)-1))
    
    # Convert x to 8-bit signed binary
    if x < 0:
        return format(2**8 + x, "08b")
    else:
        return format(x, "08b")

counter = 0
with open("sigmoid_approx.txt", "w") as f:
    for i in x:
        sigmoid_fixed = sigmoid(i/n)
        sigmoid_int = int(((2**7)-1) * sigmoid_fixed)
        f.write("8'b" + str(to_n_wide_bin(i)) + " : output_data = 8'b" + str(to_n_wide_bin(sigmoid_int)) + ";\n")
        y.append(sigmoid_int)
        counter += 1

print(counter)

plt.plot(x, y)
plt.title("Sigmoid function estimation")
plt.xlabel("Input value")
plt.ylabel("Output value")
#plt.show()
plt.savefig('sigmoid_plot.png', dpi=400)