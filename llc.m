%% set image path and categories
image_dir = 'datasets/scene-category'; 
data_dir = 'datasets/scene-category-llc';
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
addpath('lib/spatialpyramid-llc');
% parameters
params.maxImageSize = 1000;
params.gridSpacing = 8;
params.patchSize = 16;
params.dictionarySize = 200;
params.numTextonImages = 50;
params.pyramidLevels = 3;
params.oldSift = false;
tic;
% training set
pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);
% testing set
pfig = sp_progress_bar('Building Spatial Pyramid');
BuildHistograms(filenames_test, image_dir, data_dir, '_sift.mat', params, true, pfig);
pyramid_test = CompilePyramid(filenames_test, data_dir, sprintf('_texton_ind_%d.mat',params.dictionarySize), params, true, pfig);
close(pfig);
clear pfig;
rmpath('lib/spatialpyramid-llc');

%% train SVM without histogram intersection
% train SVM and predict
% addpath('lib/libsvm-3.20/matlab');
% model_linear = svmtrain(labels_train, pyramid_train, '-t 0');
% [labels_test_linear, accuracy_linear, ~] = svmpredict(labels_test, pyramid_test, model_linear);
% rmpath('lib/libsvm-3.20/matlab');
% % generate confusion matrix
% confusion_matrix_linear = confusionmat(labels_test, labels_test_linear);
% confusion_matrix_linear = confusion_matrix_linear ./ repmat(sum(confusion_matrix_linear, 2), 1, num_categories);
% figure;
% imshow(confusion_matrix_linear, 'InitialMagnification', 10000);

%% train SVM with histogram intersection
% precompute kernel
addpath('lib/spatialpyramid-llc');
kernel_train = hist_isect(pyramid_train, pyramid_train);
kernel_test = hist_isect(pyramid_test, pyramid_train);
rmpath('lib/spatialpyramid-llc');
% train SVM and predict
addpath('lib/libsvm-3.20/matlab');
model_kernel = svmtrain(labels_train, [(1 : num_images_train)' kernel_train], '-t 4');
[labels_test_kernel, accuracy_kernel, ~] = svmpredict(labels_test, [(1 : num_images_test)', kernel_test], model_kernel);
rmpath('lib/libsvm-3.20/matlab');
% generate confusion matrix
confusion_matrix_kernel = confusionmat(labels_test, labels_test_kernel);
confusion_matrix_kernel = confusion_matrix_kernel ./ repmat(sum(confusion_matrix_kernel, 2), 1, num_categories);
figure;
imshow(confusion_matrix_kernel, 'InitialMagnification', 10000);
%HeatMap(confusion_matrix_kernel)