'''
@File    :   sigmoid_value_generation.py
@Time    :   2023/11/24 09:46:47
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   k337364@gmail.com
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
'''

import math
import matplotlib.pyplot as plt

def sigmoid_fixed_point(x, num_fractional_bits=5, num_integer_bits=3):
    # Calculate the sigmoid function value
    sigmoid_value = 1 / (1 + math.exp(-x))
    
    # Scale the sigmoid value to the fixed-point representation
    fixed_point_value = int(sigmoid_value * (2**(num_fractional_bits)))

    # Ensure the value is within the representable range [0, 2^(num_fractional_bits) - 1]
    fixed_point_value = min(2**(num_fractional_bits) - 1, fixed_point_value)
    
    return fixed_point_value

def create_sigmoid_lookup_table(filename='sigmoid_lookup_table.txt', num_fractional_bits=5, num_integer_bits=3, start=-4, end=3.96875, step=0.03125):
    # Calculate the sigmoid values and create the lookup table
    lookup_table = [
        (
            format(int(x * 2**num_fractional_bits) & 0xFF, '08b'),
            format(sigmoid_fixed_point(x, num_fractional_bits, num_integer_bits), '08b')
        ) 
        for x in [start + i * step for i in range(int((end - start) / step) + 1)]
    ]
    
    # Write the lookup table to a text file
    with open(filename, 'w') as file:
        for fixed_point_input, fixed_point_output in lookup_table:
            file.write("8'b" + str(fixed_point_input) + " : output_data = 8'b" + str(fixed_point_output) + ";\n")

    return lookup_table

def plot_sigmoid_lookup_table(lookup_table):
    start=-4
    end=3.96875
    step=0.03125
    #x_values = [float(int(x, 2)) / (2**5) for x, _ in lookup_table]
    x_values = [start + i * step for i in range(int((end - start) / step) + 1)]
    y_values = [int(y, 2) / (2**5) for _, y in lookup_table]

    plt.plot(x_values, y_values)
    plt.title('Sigmoid Lookup Table')
    plt.xlabel('Input (Fixed Point)')
    plt.ylabel('Sigmoid Output (Fixed Point)')
    plt.ylim(0, 1)
    plt.grid(True)
    plt.savefig("sigmoid_plot_V2.png", dpi=400)

# Create the sigmoid lookup table
lookup_table = create_sigmoid_lookup_table()

# Plot the sigmoid lookup table
plot_sigmoid_lookup_table(lookup_table)