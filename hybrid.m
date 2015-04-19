%% set image path and categories
image_dir = 'datasets/scene-category'; 
llc_dir = '../features/scene-category-llc-all';
ob_dir = '../features/scene-category-objectbank';
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

%% extract features - LLC
addpath('lib/spatialpyramid-llc');
% parameters
params.maxImageSize = 1000;
params.gridSpacing = 8;
params.patchSize = 16;
params.dictionarySize = 1024;
params.numTextonImages = 1500; % use all training images
params.pyramidLevels = 3;
params.oldSift = true;
params.useCodebookOptim = 1;
params.useKMeansPP = 1;
params.sigma = 10;
params.lambda = 50;
params.k = 5;
tic;
% training set
llc_train = BuildPyramid(filenames_train, image_dir, llc_dir, params, true, false);
% testing set
llc_test = BuildPyramid(filenames_test, image_dir, llc_dir, params, true, false);
rmpath('lib/spatialpyramid-llc');

%% extract features - Object Bank
addpath('lib/objectBank/partless');
feature_dim = 44604;
ob_train = zeros(num_images_train, feature_dim);
ob_test = zeros(num_images_test, feature_dim);
fprintf('Extracting features for training set images (%d)\n', num_images_train);
for i = 1 : num_images_train
    if ~mod(i, 5),
       fprintf('.');
    end
    if ~mod(i, 100),
        fprintf(' %d images processed\n', i);
    end
    img_path = fullfile(image_dir, filenames_train{i});
    [subfolder, filename] = fileparts(filenames_train{i});
    feature_path = fullfile(ob_dir, subfolder);
    ob_train(i, :) = getfeat_single_image(img_path, filename, feature_path);
end
fprintf('Extracting features for testing set images (%d)\n', num_images_test);
for i = 1 : num_images_test
    if ~mod(i, 5),
       fprintf('.');
    end
    if ~mod(i, 100),
        fprintf(' %d images processed\n', i);
    end
    img_path = fullfile(image_dir, filenames_test{i});
    [subfolder, filename] = fileparts(filenames_test{i});
    feature_path = fullfile(ob_dir, subfolder);
    ob_test(i, :) = getfeat_single_image(img_path, filename, feature_path);
end
clear img_path subfolder filename feature_path;
rmpath('lib/objectBank/partless');

%% train classifier
% concatenate feature vectors
features_train = sparse([llc_train, ob_train]);
features_test = sparse([llc_test, ob_test]);
% train LR and predict
tic
addpath('lib/liblinear-1.96/matlab');
model_linear = train(labels_train, features_train, '-s 6 -c 10');
[labels_test_linear, accuracy_linear, ~] = predict(labels_test, features_test, model_linear);
rmpath('lib/liblinear-1.96/matlab');
toc
% generate confusion matrix
targets = false(num_categories, num_images_test);
outputs = targets;
for i = 1 : num_images_test
    targets(labels_test(i), i) = true;
    outputs(labels_test_linear(i), i) = true;
end
figure;
plotconfusion(targets, outputs);
confusion_matrix_linear = confusionmat(labels_test, labels_test_linear);
confusion_matrix_linear = confusion_matrix_linear ./ repmat(sum(confusion_matrix_linear, 2), 1, num_categories);
trace(confusion_matrix_linear) / num_categories