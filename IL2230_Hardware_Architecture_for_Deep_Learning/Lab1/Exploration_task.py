'''
@File    :   Exploration_task.py
@Time    :   2023/11/08 11:07:08
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   k337364@gmail.com
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
'''


import os
import torch
import torchvision
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
import torchvision.transforms as transforms
from torchsummary import summary

import numpy as np
import matplotlib.pyplot as plt


transform = transforms.Compose(
    [transforms.ToTensor(),
     transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))])

batch_size = 4

trainset = torchvision.datasets.CIFAR10(root='./Task 1/3.2/data', train=True,
                                        download=False, transform=transform)
trainloader = torch.utils.data.DataLoader(trainset, batch_size=batch_size,
                                          shuffle=True, num_workers=2)

testset = torchvision.datasets.CIFAR10(root='./Task 1/3.2/data', train=False,
                                       download=False, transform=transform)
testloader = torch.utils.data.DataLoader(testset, batch_size=batch_size,
                                         shuffle=False, num_workers=2)

classes = ('plane', 'car', 'bird', 'cat',
           'deer', 'dog', 'frog', 'horse', 'ship', 'truck')


# Define a function to train and save a model
def train_and_save_model(net, model_name):
    if not os.path.isfile(f'./Task 1/3.3/models/{model_name}.pth'):
        # Loss and optimizer
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.SGD(net.parameters(), lr=0.001, momentum=0.9)

        # Training loop
        for epoch in range(2):
            running_loss = 0.0
            for i, data in enumerate(trainloader, 0):
                inputs, labels = data
                optimizer.zero_grad()
                outputs = net(inputs)
                loss = criterion(outputs, labels)
                loss.backward()
                optimizer.step()
                running_loss += loss.item()
                if i % 2000 == 1999:
                    print(f'[{epoch + 1}, {i + 1:5d}] loss: {running_loss / 2000:.3f}')
                    running_loss = 0.0

        print(f'\nFinished Training of {model_name}')
        print("----------------------------------------------------------------------------\n")

        # Save the model
        PATH = f'./Task 1/3.3/models/{model_name}.pth'
        torch.save(net.state_dict(), PATH)

# Define a function to create a CNN model based on the given parameters
def create_cnn_model(C1, C3, activation_function = F.relu):
    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.conv1 = nn.Conv2d(3, C1, 5)
            self.pool = nn.MaxPool2d(2, 2)
            self.conv2 = nn.Conv2d(C1, C3, 5)
            self.fc1 = nn.Linear(C3 * 5 * 5, 120)
            self.fc2 = nn.Linear(120, 84)
            self.fc_final = nn.Linear(84, 10)

        def forward(self, x):
            x = self.pool(activation_function(self.conv1(x)))
            x = self.pool(activation_function(self.conv2(x)))
            x = torch.flatten(x, 1)
            x = activation_function(self.fc1(x))
            x = activation_function(self.fc2(x))
            x = self.fc_final(x)
            return x

    return Net()


def cnn_9_layers():
    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.conv1 = nn.Conv2d(3, 6, 3) 
            self.pool = nn.MaxPool2d(2, 2)
            self.conv2 = nn.Conv2d(6, 12, 3)
            self.conv3 = nn.Conv2d(12, 16, 3)
            self.fc1 = nn.Linear(16 * 2 * 2, 120)
            self.fc2 = nn.Linear(120, 84)
            self.fc3 = nn.Linear(84, 10)

        def forward(self, x):
            x = self.pool(F.relu(self.conv1(x)))
            x = self.pool(F.relu(self.conv2(x)))
            x = self.pool(F.relu(self.conv3(x)))
            x = torch.flatten(x, 1) # flatten all dimensions except batch
            x = F.relu(self.fc1(x))
            x = F.relu(self.fc2(x))
            x = self.fc3(x)
            return x

    return Net()

def cnn_11_layers():
    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.conv1 = nn.Conv2d(3, 6, 2) 
            self.pool = nn.MaxPool2d(2, 2, padding=1)
            self.conv2 = nn.Conv2d(6, 8, 2)
            self.conv3 = nn.Conv2d(8, 12, 2)
            self.conv4 = nn.Conv2d(12, 16, 2)
            self.fc1 = nn.Linear(16 * 2 * 2, 120)
            self.fc2 = nn.Linear(120, 84)
            self.fc3 = nn.Linear(84, 10)

        def forward(self, x):
            x = self.pool(F.relu(self.conv1(x)))
            x = self.pool(F.relu(self.conv2(x)))
            x = self.pool(F.relu(self.conv3(x)))
            x = self.pool(F.relu(self.conv4(x)))
            x = torch.flatten(x, 1) # flatten all dimensions except batch
            x = F.relu(self.fc1(x))
            x = F.relu(self.fc2(x))
            x = self.fc3(x)
            return x

    return Net()

def cnn_13_layers():
    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.conv1 = nn.Conv2d(3, 6, 2) 
            self.pool = nn.MaxPool2d(2, 2, padding=1)
            self.conv2 = nn.Conv2d(6, 8, 2)
            self.conv3 = nn.Conv2d(8, 12, 2)
            self.conv4 = nn.Conv2d(12, 14, 2)
            self.conv5 = nn.Conv2d(14, 16, 2)
            self.fc1 = nn.Linear(16 * 1 * 1, 120)
            self.fc2 = nn.Linear(120, 84)
            self.fc3 = nn.Linear(84, 10)

        def forward(self, x):
            x = self.pool(F.relu(self.conv1(x)))
            x = self.pool(F.relu(self.conv2(x)))
            x = self.pool(F.relu(self.conv3(x)))
            x = self.pool(F.relu(self.conv4(x)))
            x = self.pool(F.relu(self.conv5(x)))
            x = torch.flatten(x, 1) # flatten all dimensions except batch
            x = F.relu(self.fc1(x))
            x = F.relu(self.fc2(x))
            x = self.fc3(x)
            return x

    return Net()
    

def verify_models_result(all_models):
    
    results = []
    model_names = []
    for i in range(len(all_models)):
        # Define the model architecture inside the function
        net = all_models[i][1]
        PATH = f'./Task 1/3.3/models/{all_models[i][0]}.pth'
        net.load_state_dict(torch.load(PATH))
        net.eval()  # Set the model to evaluation mode
        correct = 0
        total = 0

        # since we're not training, we don't need to calculate the gradients for our outputs
        with torch.no_grad():
            for data in testloader:
                images, labels = data
                # calculate outputs by running images through the network
                outputs = net(images)
                # the class with the highest energy is what we choose as the prediction
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()
        accuracy = 100 * correct / total
        print(f'Accuracy of the network {all_models[i][0]} on the 10000 test images: {100 * correct / total:.2f}%')
        results.append(accuracy)
        model_names.append(all_models[i][0])
        
    # Figure Size
    fig, ax = plt.subplots(figsize =(16, 9))
    
    # Horizontal Bar Plot
    ax.barh(model_names, results)
    
    # Remove axes splines
    for s in ['top', 'bottom', 'left', 'right']:
        ax.spines[s].set_visible(False)
    
    # Remove x, y Ticks
    ax.xaxis.set_ticks_position('none')
    ax.yaxis.set_ticks_position('none')
    
    # Add padding between axes and labels
    ax.xaxis.set_tick_params(pad = 5)
    ax.yaxis.set_tick_params(pad = 10)
    
    # Add x, y gridlines
    ax.grid(visible = True, color ='grey',
            linestyle ='-.', linewidth = 0.5,
            alpha = 0.2)
    
    # Show top values 
    ax.invert_yaxis()
    
    # Add annotation to bars
    for i in ax.patches:
        plt.text(i.get_width()+0.2, i.get_y()+0.5, 
                str(round((i.get_width()), 2)),
                fontsize = 10, fontweight ='bold',
                color ='grey')
    
    ax.set_title('Model verification results',
                loc ='left', fontweight = 'bold')
    ax.set_ylabel('Model', fontweight='bold')
    ax.set_xlabel('Accuracy [%]', fontweight='bold')
    #plt.show()
    PATH = f'./Task 1/3.3/model_verification_result_total.png'
    plt.savefig(PATH)
    

if __name__ == '__main__':
    
    all_models = []

    # ------------------------------- Standard net ------------------------------- #
    model_name = f'cifar_net'
    net = create_cnn_model(6, 16)
    all_models.append([model_name, net])
    train_and_save_model(net, model_name)

    # ---------------- Sweep over different configurations for C1 ---------------- #
    for C1 in range(8, 14, 2):
        model_name = f'cifar_net_C1_{C1}'
        net = create_cnn_model(C1, 16)
        all_models.append([model_name, net])
        train_and_save_model(net, model_name)

    # ---------------- Sweep over different configurations for C3 ---------------- #
    for C3 in range(20, 32, 4):
        model_name = f'cifar_net_C3_{C3}'
        net = create_cnn_model(6, C3)
        all_models.append([model_name, net])
        train_and_save_model(net, model_name)

    # ----------------- Sweep over different convolutional depths ---------------- #
    
    for layer in range(9, 15, 2):
        model_name = f'cifar_net_layers_{layer}'
        
        if(layer == 9):
            net = cnn_9_layers()
        elif(layer == 11):
            net = cnn_11_layers()
        else:
            net = cnn_13_layers()
            summary(net, input_shape)
        
        all_models.append([model_name, net])
        input_shape = (3,32,32)
        #summary(net, input_shape)
        
        train_and_save_model(net, model_name)

    # -------------------- Use different activation functions -------------------- #
    
    # ----------------------------------- tanh ----------------------------------- #
    model_name = f'cifar_net_tanh'
    net = create_cnn_model(6, 16, F.tanh)
    all_models.append([model_name, net])
    train_and_save_model(net, model_name)

    # ---------------------------------- sigmoid --------------------------------- #
    model_name = f'cifar_net_sigmoid'
    net = create_cnn_model(6, 16, F.sigmoid)
    all_models.append([model_name, net])
    train_and_save_model(net, model_name)

    verify_models_result(all_models)