function [tune_accuracy] = llc_tune(filenames_train, labels_train, image_dir, data_dir, params)

%% parameters

if(~exist('params','var'))
    params.maxImageSize = 1000;
    params.gridSpacing = 8;
    params.patchSize = 16;
    params.dictionarySize = 200;
    params.numTextonImages = 50;
    params.pyramidLevels = 3;
    
    %added
    params.useCodebookOptim = 1;
    params.useKMeansPP = 1;
    params.sigma = 10;
    params.lambda = 50;
    params.k = 5;
end
if(~isfield(params,'maxImageSize'))
    params.maxImageSize = 1000;
end
if(~isfield(params,'gridSpacing'))
    params.gridSpacing = 8;
end
if(~isfield(params,'patchSize'))
    params.patchSize = 16;
end
if(~isfield(params,'dictionarySize'))
    params.dictionarySize = 200;
end
if(~isfield(params,'numTextonImages'))
    params.numTextonImages = 50;
end
if(~isfield(params,'pyramidLevels'))
    params.pyramidLevels = 3;
end
if(~exist('canSkip','var'))
    canSkip = 1;
end
if(~exist('saveSift','var'))
    saveSift = 1;
end

%added
if(~isfield(params,'sigma'))
    params.sigma = 10;
end
if(~isfield(params,'lambda'))
    params.lambda = 50;
end
if(~isfield(params,'k'))
    params.k = 5;
end
if(~isfield(params,'useCodebookOptim'))
    params.useCodebookOptim = 1;
end
if(~isfield(params,'useKMeansPP'))
    params.useKMeansPP = 1;
end

%% extract spatial pyramid histograms
addpath('lib/spatialpyramid-llc');
tic;

% training set
pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);

rmpath('lib/spatialpyramid-llc');

%% train SVM
% train SVM and predict
addpath('lib/liblinear-1.96/matlab');
tune_accuracy = train(labels_train, sparse(pyramid_train), '-c 10 -v 10'); % five fold cross validation
rmpath('lib/liblinear-1.96/matlab');
end