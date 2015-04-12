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
params.gridSpacing = 6;
params.patchSize = 16;
params.dictionarySize = 1024;
params.numTextonImages = 50;
params.pyramidLevels = 3;
params.oldSift = true;
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

%% train SVM
% train SVM and predict
addpath('lib/liblinear-1.96/matlab');
model_linear = train(labels_train, sparse(pyramid_train), '-c 10');
[labels_test_linear, accuracy_linear, ~] = predict(labels_test, sparse(pyramid_test), model_linear);
rmpath('lib/liblinear-1.96/matlab');
% generate confusion matrix
confusion_matrix_linear = confusionmat(labels_test, labels_test_linear);
confusion_matrix_linear = confusion_matrix_linear ./ repmat(sum(confusion_matrix_linear, 2), 1, num_categories);
figure;
imshow(confusion_matrix_linear, 'InitialMagnification', 4000);