# CS766 Assignment 3 - Locality-constrained Linear Coding for Scene Classification

## Links
* Repository: <https://github.com/cbod/cs766-llc>
* Wiki: <https://github.com/cbod/cs766-llc/wiki>
* Result, credits and usage info can be found in the offline html wiki or in our Github wiki.

## Group Members:
Ke Ma, Christopher Bodden

## Assignment Description:
For this project we implemented Locality-constrained Linear Coding (LLC) image classification method and applied it to a specific dataset of natural scene images. LLC coding improves upon the Vector Quantization (VQ) coding method by preserving a feature's spatial context.

## Features:
This is a brief description of our implementation. More details can be found in the other pages of the wiki.

### Basic Features:
* Modified the basic spatial pyramid to use Locality-constrained Linear Coding (LLC) with max pooling.
* Evaluated LLC against VQ
* Tuned parameters for codebook size and k nearest neighbors to maximize accuracy.

### "Bonus" Features:
* Combined LLC with Object Bank to improve accuracy
* Implemented codebook optimization (algorithm 4.1 in the paper)
* Implemented K-means++ to select K-means initial centers more intelligently
* Built a GUI to easily run our pipeline

## Program Screenshot:
[[images/GUI_Snapshot.jpg|alt=Program Screenshot]]

## Best Result:
Our best results came from **combining LLC and object bank by summing up decision values** (dicussed in results). The classification accuracy with this technique is **81.34%** which is above the state-of-the-art SPM results. The averaged class accuracy for all classes is **80.65%**.

## Important Notes:
This project uses many libraries and saves dictionaries/pyramids/object bank data as intermediate files. It is critical that the following directory structure is maintained or the code will not function properly. The most important relationship to preserve is that between the MATLAB scripts and the libraries & dataset.

[[images/DIR_structure.jpg|alt=Directory Structure]]