---
title: "CNNs"
date: 2024-05-21
aliases:
  - /blog/2024/05/21/Convolutional_Neural_Networks.html
tags:
  - "deeplearning"
math: true
ShowToc: true
TocOpen: false
---


This is a quick skim notes for [CS231n Introduction to CNN lecture 7](https://www.youtube.com/watch?v=LxfUGhug-iQ&list=PLkt2uSq6rBVctENoVBg1TpCC7OQi31AlC&index=8), I used slides from this lecture to create notes and this is NOT an attempt to replicate [notes by cs231n](https://cs231n.github.io/convolutional-networks/), its already the best notes on CNNs out there.

CNNs are similar to ordinary neural networks, they have trainable weights and bias, receives input, bunch of trainable layers followed with non-linearity. Each layer is completely differentiable, means they can learn. At the end an output layer predicting classes or so.

So what changes? ConvNet architecture make the explicit assumption that the inputs are image which allows us to encode certain properties into the architecture. These then make the forward function more efficient to implement and vastly reduce the amount of parameter in the network.

**Why can't regular NNs don't scale to images?**  

Consider an image from CIFAR-10 dataset, size 32x32x3, input neurons would be 32x32x3 = 3072 weights. Good? Now consider an image 200x200x3 image, 120,000 weights in the first layer, moreover we would almost certainly want to have several such neurons, so the parameters would add up quickly. Clearly, this full connectivity is wasteful and the huge number of parameters would quickly lead to overfitting.

**3D volumes of neurons**  

CNN's take the advantage of the fact that the input are images and use the architecture in a more sensible way. In particular, unlike the regular neural networks the layer of convolution net have neurons arranged in three dimensions: Height, width and depth. The depth here is not the depth of the whole neural net. But instead, it's the depth of trainable weights. A good visualization:

<hr>
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/neural_net2.jpeg" alt="Regular 3-layer fully connected neural network diagram" style="max-width: 70%; height: auto;">
  <figcaption><strong>Fig. 1.</strong> A regular 3-layer fully connected Neural Network (source: <a href="https://cs231n.github.io/convolutional-networks/">CS231n</a>).</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn.jpeg" alt="Convolutional Neural Network arranging neurons in 3D volumes (height, width, depth)" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 2.</strong> A ConvNet arranges neurons in three dimensions (height, width, depth); the red block represents an RGB input image of size 28 × 28 × 3 (source: <a href="https://cs231n.github.io/convolutional-networks/">CS231n</a>).</figcaption>
</figure>
<hr>

## Convolve
*Filters*, also called *kernels*, are small (typically 3x3 or 5x5) used to slide over the image spatially, computing dot products. The filters also have depth, eg. 3x3x96 here 96 is depth of the kernel. The depth of kernel should be equal to the depth of the input. If the input is 32x32x3 image, where 3 is ~RGB. then kernel would have depth 3 (3x3x**3** or 5x5x**3**).

> in the above case, **spatial** dimension is the 32x32 (height and width of input).

<hr>
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn1.png" alt="Convolutional kernel sliding across an input image volume" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 3.</strong> Kernels slide over the image, to convolve/feature extract.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn2.png" alt="Activation map spatial dimensions shrinking relative to the input volume" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 4.</strong> The dimension of the activation map (right) depends on input (left) size & depth and the kernel size & depth. Notice the reduction in size of the output image.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn3.png" alt="Multiple filters producing separate activation maps across input channels" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 5.</strong> let's say, there are 2 input channel (shown in the image 'consider a second green filter', blue and green) the kernel will also be slide through all location of the 2nd channel. Creates another output activations. Each kernel create a output activation for each channel.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn4.png" alt="Six 5x5 kernels producing a 6x28x28 stack of activation maps" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 6.</strong> Now, if there are 6, 5x5 kernel. we will get 6 seperate activation maps.  
  6x28x28 in this case.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/cnn5.png" alt="Stacked convolutional layers interleaved with ReLU non-linearities" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 7.</strong> Stack this up, plus non-linearlity (ReLU) on the activation maps.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/math.png" alt="Overview of stacked Conv and ReLU layers transforming an input image into feature maps" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 8.</strong> an overview of input to the conv layers and its output. each convs are followed by non-linearity (for example, ReLU), just stack them and we have a architecture?</figcaption>
</figure>
<hr>

**An overview of the ConvNet architecture**  
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/convnet.jpeg" alt="Full ConvNet architecture transforming raw image pixels into class scores" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 9.</strong> The activations of an example ConvNet architecture. The initial volume stores the raw image pixels (left) and the last volume stores the class scores (right). The middle shows visulizations of activations, since it is difficult to visualize 3D, here the representation is in 2D.</figcaption>
</figure>

**How do we know, the size of the output after convolution?**  
`(N-F)/S + 1`, where `N` is the number if input dimension, `F` is the kernel dimension. `S` is stride.

**Oh yes, what is Stride?**  

Kernels slide through the input layer, **Stride** refers to number of pixels the filter mover over the input image during convolution ([see some gifs](https://github.com/jerpint/cnn-cheatsheet?tab=readme-ov-file#strided-1-and-stride-2))

**Padding**  

In practice, it is common to pad the input image with 0s around the edges.

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/pad.png" alt="Zero-padding around the spatial border of an input feature map" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 10.</strong> Good effect, we can control the spatial size of the output. Example, to retain the original size of input image, we can use (F-1)/2 padding. where F is the filter dim.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/pad2.png" alt="Output spatial dimensions calculation with zero-padding applied" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 11.</strong> Worked example verifying that zero-padding preserves spatial dimensions after convolution.</figcaption>
</figure>

**math time, calculate how many trainable params**  

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/params.png" alt="Calculation of trainable kernel parameters and biases in a convolutional layer" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 12.</strong> kernels are trainable</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/common.png" alt="Common hyperparameter settings for convolutional filter size, stride, and padding" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 13.</strong> some common settings for Convolutions</figcaption>
</figure>


**we can also have 1x1 Kernels**  

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/1x1.png" alt="1x1 convolution reducing channel depth from 64 to 32 while keeping spatial dimensions unchanged" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 14.</strong> 1x1 kernels are used for dimensionality reduction without altering spatial dimensions, 64 -> 32 (halved but the spatial dimension remains same)</figcaption>
</figure>

### Summary 1: Convolution Layer
- Accepts input of shape **W, H, D**
- Requires hyperparameters
  - Number of Kernels-- **N**
  - Kernel dim-- **F**
  - Stride-- **S**
  - Padding-- **P**
<hr>

**The brain/neuron view of CONV layer**  

Recall how the activation map depth is equal to the number of kernels.

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/neuron.png" alt="Neuron-level view of a local receptive field in a convolutional layer" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 15.</strong> a neuron view of convolution</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/neuron2.png" alt="Element-wise dot product between a local image patch and a convolutional filter" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 16.</strong> the output of a patch from img and element wise multiplication of kernel is the size of kernel itself, then we calculate the sum of it. ~Dot product. This creates a single activation in the activation layer</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/neuron3.png" alt="Spatially arranged neurons sharing weights across stacked activation channels" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 17.</strong> Create layers spatially, they are not interconnected. It similar to channels stacked.</figcaption>
</figure>

**Pooling Layer**  

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/pool.png" alt="Spatial downsampling via a pooling layer reducing height and width" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 18.</strong> This throws away some spatial information, but dont worry, not all information is equally valuable. Hypothetically, Pooling layer discards some less important details.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/pool2.png" alt="2x2 max pooling with stride 2 taking the maximum value in each window" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 19.</strong> Max pooling is generally better than average pooling because it preserves the most prominent features and introduces non-linearity, making it more effective in capturing key patterns and reducing overfitting.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/pool3.png" alt="Common pooling hyperparameters: F=2, S=2 and F=3, S=2" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 20.</strong> Common pooling hyperparameters: kernel size <code>F = 2, stride S = 2</code> and <code>F = 3, S = 2</code>.</figcaption>
</figure>
<hr>

### Case Study

#### **LeNet-5**
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/lenet5.png" alt="LeNet-5 architecture diagram: Conv-Pool-Conv-Pool-Conv-FC" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 21.</strong> Architecture: [Conv-pool-Conv-pool-conv-FC]</figcaption>
</figure>

<hr>

#### **AlexNet**
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/alex.png" alt="AlexNet first convolutional layer using 96 kernels of size 11x11 at stride 4" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 22.</strong> Increased the kernel depth, from 6 to 96. Applied kernel of size 11x11 at stride of 4.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/alex2.png" alt="AlexNet layer-by-layer architecture with ReLU activations and local response normalization" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 23.</strong> AlexNet was the first paper to use ReLU. This made ReLU popular. There are ReLU after each convolution layers and FC layers. We don't use the NORM layers used in AlexNet now, because it doesn't actually gives any improvement.</figcaption>
</figure>

Architecture of AlexNet: `C = Conv`, `P = Pool`, `O = Output layer`  
`[C-P-C-P-C-C-C-P-FC-FC-O-Softmax]`

some details:  
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/alex3.png" alt="AlexNet training details including learning rate decay by 10x on validation accuracy plateau" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 24.</strong> LR is reduced by 10, when Val accuracy plateaus</figcaption>
</figure>

<hr>

#### **ZFNet**
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/ZFnet.png" alt="ZFNet architecture refining AlexNet with smaller stride and more filters" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 25.</strong> Similar architecture to AlexNet but increased number of kernels (N)</figcaption>
</figure>

<hr>

#### **VGGNet**
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/vgg.png" alt="VGGNet architecture diagram showing 13 convolutional layers and pooling stages" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 26.</strong> VGGNet architecture overview (source: <a href="https://arxiv.org/abs/1409.1556">Simonyan &amp; Zisserman, 2014</a>).</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/vgg2.png" alt="Hand-drawn diagram of VGGNet's 13 convolutional layers and pooling stages" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 27.</strong> A rough diagram that I made, shows there are 13 Conv Layers used in VGG net (there are also pooling)</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/vgg3.png" alt="VGGNet memory and parameter footprint breakdown by layer" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 28.</strong> ~by Andrej Karpathy</figcaption>
</figure>

Memory footprint of VGGNet shows,
- Most memory is in early CONV layer (3M)
- Most Parameters are in late FC layers (10M)
- 93MB/image in forward pass alone

**Average Pooling Layer replaces FC layer in the end**  
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/avgpool.png" alt="Global average pooling reducing a 7x7x512 feature map to a 1x512 vector" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 29.</strong> Global average pooling collapsing each 7×7 spatial slice of a 7×7×512 volume into a single value (1×512), replacing parameter-heavy FC layers.</figcaption>
</figure>
The example is from the FC layer of VGG net, the last POOL2 output is of shape: 7x7x512, where 7x7 are spatial dim and 512 is depth/volume. each 7x7 is averaged pool to 1. reducing the size quite a lot.

<hr>

#### **GoogLeNet** (introduced inception)
<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/google.png" alt="GoogLeNet Inception module architecture diagram" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 30.</strong> GoogLeNet Inception module combining multi-scale convolutions in parallel (source: <a href="https://arxiv.org/abs/1409.4842">Szegedy et al., 2014</a>).</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/google2.png" alt="GoogLeNet full network replacing final FC layers with average pooling" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 31.</strong> This paper introduced Inception module, remove last FC layer with AveragePool layer to reduce parameters.</figcaption>
</figure>

<hr>

#### **ResNet**

In 2015, ResNet won 1st place in many competition at the same time. GoogleNet was 22 layers, introduced resnet was 152 layers. 

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/meme.png" alt="Stack more layers meme illustrating naive depth scaling" style="max-width: 50%; height: auto;">
  <figcaption><strong>Fig. 32.</strong> <br>So increasing layers == win?</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/resnet.png" alt="Training and test error curves showing 56-layer plain network underperforming 20-layer network" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 33.</strong> Well, yes thats what scaling hypothesis says. But increasing layers is challenging. Problems with vanilla nets, increasing the number of layers converges in training (left img, dashed lines) but the validation error of 56 layer > 20 layer net. Which makes no sense.</figcaption>
</figure>

ResNet took, 2-3 weeks of training on 8 GPU, but at runtime, its faster than VGGNet, even though it has 8x more layers.

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/resnet2.png" alt="Residual block diagram with identity skip connection F(x) + x" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 34.</strong> Residual block with an identity skip connection computing <code>F(x) + x</code> (source: <a href="https://arxiv.org/abs/1512.03385">He et al., 2015</a>).</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/resnet3.png" alt="Bottleneck residual block with 1x1, 3x3, and 1x1 convolutions" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 35.</strong> Bottleneck residual block using 1×1 convolutions to reduce and restore channel dimensions around a 3×3 convolution.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/resnet4.png" alt="Comparison of ResNet identity skip connections and Highway Network gated skip connections" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 36.</strong> Highway network is also a good paper by Jürgen Schmidhuber. Introduced just before ResNet. The Skip connection in Highway network had trainable weights. where as ResNet Skip connections is literally vanilla addition of input to output.</figcaption>
</figure>

<hr>

#### **AlphaGo** (policy network?)

Playing Go (harder than chess) using CNNs? The 48 rules of playing Go embedding into the image's channel?

<figure style="text-align: center;">
  <img src="/assets/Convolutional_Neural_Networks/go.png" alt="AlphaGo convolutional policy network architecture taking a 19x19x48 board representation" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 37.</strong> AlphaGo policy network: a 19×19×48 board representation processed by convolutional layers to output move probabilities (source: <a href="https://www.nature.com/articles/nature16961">Silver et al., 2016</a>).</figcaption>
</figure>

### Summary 2: Trends
- ConvNets Stack Conv, pool, FC layers
- Smaller filters and deep architecture
- get rid of Pool/FC layers (just convs) 
  - Treads toward stride-convs only layer, where you try to reduce image dimension (not depth) using convs instead of using pooling layer.
  - ResNet/GoogleNet challenge this paradigm


<!--
#### Computational Considerations
`TODO`

### R-CNN
`TODO`

### Fast-CNN
`TODO`

### Faster-CNN
`TODO`

### Visualizing CNN
`TODO`

### DeepDream
`TODO`

### Transfer Style of image
`TODO`

### Chaos-- Fooling CNN using Adverserial modified images
`TODO` -->

## References
- [Andrej Karpathy lecture on CNNs](https://youtu.be/LxfUGhug-iQ?si=Sq-eXEBLHASwBR_i)