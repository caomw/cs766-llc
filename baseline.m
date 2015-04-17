%% Original SPM baseline test script
%
% Ke Ma & Chris Bodden
%

%% set image path and categories
image_dir = 'datasets/scene-category'; 
data_dir = '../features/scene-category-baseline';
categories = {'bedroom', 'CALsuburb', 'industrial', 'kitchen',...
    'livingroom', 'MITcoast', 'MITforest', 'MIThighway', 'MITinsidecity',...
    'MITmountain', 'MITopencountry', 'MITstreet', 'MITtallbuilding',...
    'PARoffice', 'store'};

%% construct training and testing sets
filenames_train = {};
labels_train = [];
filenames_test = {};
labels_test = [];
num_categories = length(categories);
for k = 1 : num_categories
    files = dir(fullfile(image_dir, categories{k}, '*.jpg'));
    num_files = size(files, 1);
    filenames = cell(num_files, 1);
    for f = 1 : num_files
        filenames{f} = fullfile(categories{k}, files(f).name);
    end
    % training set
    size_train = 100;
    filenames_train = [filenames_train; filenames(1 : size_train)];
    labels_train = [labels_train; ones(size_train, 1) * k];
    % testing set
    size_test = num_files - 100;
    filenames_test = [filenames_test; filenames(size_train + 1 : end)];
    labels_test = [labels_test; ones(size_test, 1) * k];
end
num_images_train = length(labels_train);
num_images_test = length(labels_test);
clear k files num_files filenames f size_train size_test;

%% extract spatial pyramid histograms
addpath('lib/spatialpyramid');
% parameters
params.maxImageSize = 1000;
params.gridSpacing = 8;
params.patchSize = 16;
params.dictionarySize = 200;
params.numTextonImages = 50;
params.pyramidLevels = 3;
params.oldSift = true;
tic;
% training set
pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);
% testing set
pyramid_test = BuildPyramid(filenames_test, image_dir, data_dir, params, true, false);
rmpath('lib/spatialpyramid');

%% train SVM without histogram intersection
% train SVM and predict
addpath('lib/liblinear-1.96/matlab');
model_linear = train(labels_train, sparse(pyramid_train), '-c 10');
[labels_test_linear, accuracy_linear, ~] = predict(labels_test, sparse(pyramid_test), model_linear);
rmpath('lib/liblinear-1.96/matlab');
% generate confusion matrix
targets = false(num_categories, num_images_test);
outputs = targets;
for i = 1 : num_images_test
    targets(labels_test(i), i) = true;
    outputs(labels_test_linear(i), i) = true;
end
figure;
plotconfusion(targets, outputs);

%% train SVM with histogram intersection
% precompute kernel
addpath('lib/spatialpyramid');
kernel_train = hist_isect(pyramid_train, pyramid_train);
kernel_test = hist_isect(pyramid_test, pyramid_train);
rmpath('lib/spatialpyramid');
% train SVM and predict
addpath('lib/libsvm-3.20/matlab');
model_kernel = svmtrain(labels_train, [(1 : num_images_train)' kernel_train], '-t 4 -c 10');
[labels_test_kernel, accuracy_kernel, ~] = svmpredict(labels_test, [(1 : num_images_test)', kernel_test], model_kernel);
rmpath('lib/libsvm-3.20/matlab');
% generate confusion matrix
targets = false(num_categories, num_images_test);
outputs = targets;
for i = 1 : num_images_test
    targets(labels_test(i), i) = true;
    outputs(labels_test_kernel(i), i) = true;
end
figure;
plotconfusion(targets, outputs);