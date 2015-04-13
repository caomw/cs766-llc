%% set image path and categories
image_dir = 'datasets/scene-category'; 
data_dir = '../features/scene-category-objectbank';
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

%% extract features
addpath('lib/objectBank/partless');
feature_dim = 44604;
features_train = zeros(num_images_train, feature_dim);
features_test = zeros(num_images_test, feature_dim);
for i = 1 : num_images_train
    img_path = fullfile(image_dir, filenames_train{i});
    [subfolder, filename] = fileparts(filenames_train{i});
    feature_path = fullfile(data_dir, subfolder);
    features_train(i, :) = getfeat_single_image(img_path, filename, feature_path);
end
for i = 1 : num_images_test
    img_path = fullfile(image_dir, filenames_test{i});
    [subfolder, filename] = fileparts(filenames_test{i});
    feature_path = fullfile(data_dir, subfolder);
    features_test(i, :) = getfeat_single_image(img_path, filename, feature_path);
end
rmpath('lib/objectBank/partless');