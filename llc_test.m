% script to test llc under many conditions for k and codebook size

k_vals = [1 2 5 10 25];
codebook_vals = [512 1024 2048];
image_dir = 'datasets/scene-category'; 
data_dir = '../features/scene-category-llc';
categories = {'bedroom', 'CALsuburb', 'industrial', 'kitchen',...
    'livingroom', 'MITcoast', 'MITforest', 'MIThighway', 'MITinsidecity',...
    'MITmountain', 'MITopencountry', 'MITstreet', 'MITtallbuilding',...
    'PARoffice', 'store'};
size_train = 100;

top_c = nan;
top_k = nan;
best_acc = -Inf;
c_table = nan(length(codebook_vals) * length(k_vals));
k_table = c_table;
acc_table = c_table;
iter = 1;

% tune codebook size and k
for c = codebook_vals
    for k = k_vals        
        % parameters
        params.maxImageSize = 1000;
        params.gridSpacing = 8;
        params.patchSize = 16;
        params.dictionarySize = c;
        params.numTextonImages = 1500; % use all training images
        params.pyramidLevels = 3;
        params.oldSift = true;
        params.k = k;
        params.sigma = 10;
        params.lambda = 50;
        params.useCodebookOptim = 1;
        params.useKMeansPP = 1;
        
        % runn 10 fold cross validation for this setting
        accuracy = llc_tune(image_dir, data_dir, categories, size_train, params);
        
        if (accuracy > best_acc)
            best_acc = accuracy;
            top_c = c;
            top_k = k;
        end
        
        % record value for final table
        c_table(iter) = c;
        k_table(iter) = k;
        acc_table(iter) = acc;
        iter = iter + 1;
    end
end

% save table
results_table = table(c_table, k_table, acc_table);

%% final results & confusion matrix with best params

% parameters
params.maxImageSize = 1000;
params.gridSpacing = 8;
params.patchSize = 16;
params.dictionarySize = top_c;
params.numTextonImages = 1500; % use all training images
params.pyramidLevels = 3;
params.oldSift = true;
params.k = top_k;
params.sigma = 10;
params.lambda = 50;
params.useCodebookOptim = 1;
params.useKMeansPP = 1;

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