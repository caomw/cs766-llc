%% set image path and categories
image_dir = 'datasets/scene-category'; 
data_dir = '../features/scene-category-llc-all';
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
pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);
% testing set
pyramid_test = BuildPyramid(filenames_test, image_dir, data_dir, params, true, false);
rmpath('lib/spatialpyramid-llc');
% convert to sparse
pyramid_train = sparse(pyramid_train);
pyramid_test = sparse(pyramid_test);

%% adaboost
% initialize variables
num_hypotheses = 10;
example_weights = ones(num_images_train, 1) / num_images_train;
hypotheses = cell(num_hypotheses, 1);
hyptheses_weights = zeros(num_hypotheses, 1);
% train SVM
addpath('lib/liblinear-weights-1.96/matlab');
tic
for i = 1 : num_hypotheses
    hypotheses{i} = train(example_weights, labels_train, pyramid_train, '-c 800');
    [labels_train_predict, ~, ~] = predict(labels_train, pyramid_train, hypotheses{i});
    wrong_ids = labels_train ~= labels_train_predict;
    error = sum(wrong_ids .* example_weights);
    if error == 0
        error = min(example_weights) / 10;
    end
    correct_ids = not(wrong_ids);
    example_weights(correct_ids) = example_weights(correct_ids) * (error / (1 - error));
    example_weights = example_weights ./ sum(example_weights);
    hyptheses_weights(i) = log((1 - error) / error);
end
% predict
decval_test_all = zeros(num_images_test, num_categories);
for i = 1 : num_hypotheses
    [~, ~, decval_test] = predict(labels_test, pyramid_test, hypotheses{i});
    decval_test_all = decval_test_all + decval_test * hyptheses_weights(i);
end
[~, labels_test_predict] = max(decval_test_all, [], 2);
accuracy = sum(labels_test_predict==labels_test) / num_images_test
toc
rmpath('lib/liblinear-weights-1.96/matlab');
% generate confusion matrix
targets = false(num_categories, num_images_test);
outputs = targets;
for i = 1 : num_images_test
    targets(labels_test(i), i) = true;
    outputs(labels_test_predict(i), i) = true;
end
figure;
plotconfusion(targets, outputs);
confusion_matrix = confusionmat(labels_test, labels_test_predict);
confusion_matrix = confusion_matrix ./ repmat(sum(confusion_matrix, 2), 1, num_categories);
trace(confusion_matrix) / num_categories
