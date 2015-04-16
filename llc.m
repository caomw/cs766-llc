%% set image path and categories
image_dir = 'datasets/scene-category'; 
data_dir = '../features/scene-category-llc';
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

%% train SVM
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
h = figure;
plotconfusion(targets, outputs);
pos = get(h,'Position');
pos([3,4]) = pos([3,4]) .* 3;
set(h,'Position', pos, 'PaperPositionMode','auto');
figure_file_name = fullfile(data_dir, sprintf('confuse_%i_%i', params.dictionarySize, params.k))
print(figure_file_name,'-dpng');
close(h);