function varargout = llc_gui(varargin)
% LLC_GUI MATLAB code for llc_gui.fig
%      LLC_GUI, by itself, creates a new LLC_GUI or raises the existing
%      singleton*.
%
%      H = LLC_GUI returns the handle to a new LLC_GUI or the handle to
%      the existing singleton*.
%
%      LLC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LLC_GUI.M with the given input arguments.
%
%      LLC_GUI('Property','Value',...) creates a new LLC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before llc_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to llc_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help llc_gui

% Last Modified by GUIDE v2.5 17-Apr-2015 15:34:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @llc_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @llc_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before llc_gui is made visible.
function llc_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to llc_gui (see VARARGIN)

% Choose default command line output for llc_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes llc_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Setup initial parameters

% directory parameters
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
size_train = 100;
for k = 1 : num_categories
    files = dir(fullfile(image_dir, categories{k}, '*.jpg'));
    num_files = size(files, 1);
    filenames = cell(num_files, 1);
    for f = 1 : num_files
        filenames{f} = fullfile(categories{k}, files(f).name);
    end
    % training set
    filenames_train = [filenames_train; filenames(1 : size_train)];
    labels_train = [labels_train; ones(size_train, 1) * k];
    % testing set
    size_test = num_files - 100;
    filenames_test = [filenames_test; filenames(size_train + 1 : end)];
    labels_test = [labels_test; ones(size_test, 1) * k];
end
clear k files num_files filenames f size_train size_test;

% option values
accuracy_vals = {get(handles.text1,'String'); get(handles.text2,'String'); ... 
    get(handles.text3,'String'); get(handles.text4,'String'); get(handles.text5,'String'); ...
    get(handles.text6,'String'); get(handles.text7,'String'); get(handles.text8,'String'); ...
    get(handles.text9,'String'); get(handles.text10,'String'); get(handles.text11,'String'); ...
    get(handles.text12,'String'); get(handles.text13,'String'); get(handles.text14,'String'); ...
    get(handles.text15,'String'); get(handles.text16,'String'); get(handles.text17,'String') };
k_vals = [1 2 5 10 25 50];
codebook_vals = [256 512 1024 2048 4096];

% SPM parameters
params.maxImageSize = 1000;
params.gridSpacing = 8;
params.patchSize = 16;
params.numTextonImages = 1500; % use all training images
params.pyramidLevels = 3;
params.oldSift = true;
params.sigma = 10;
params.lambda = 50;
params.useCodebookOptim = 1;
params.useKMeansPP = 1;
params.k = k_vals(3);
params.useObjectBank = 1;
params.dictionarySize = codebook_vals(3);

% save params
setappdata(handles.figure1,'accuracy_vals', accuracy_vals);
setappdata(handles.figure1,'k_vals', k_vals);
setappdata(handles.figure1,'codebook_vals', codebook_vals);
setappdata(handles.figure1,'params', params);
setappdata(handles.figure1,'image_dir', image_dir);
setappdata(handles.figure1,'data_dir', data_dir);
setappdata(handles.figure1,'categories', categories);
setappdata(handles.figure1,'filenames_train', filenames_train);
setappdata(handles.figure1,'filenames_test', filenames_test);
setappdata(handles.figure1,'labels_train', labels_train);
setappdata(handles.figure1,'labels_test', labels_test);

% clear temp vars
clear params filenames_train filenames_test labels_train labels_test categories data_dir image_dir codebook_vals k_vals;


% --- Outputs from this function are returned to the command line.
function varargout = llc_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in push_run.
function push_run_Callback(hObject, eventdata, handles)
% hObject    handle to push_run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%
disp('Supressing warnings');
warning('off', 'all');

% clear axes
% cla(handles.confuse_plot);
set(handles.confuse_table, 'Visible', 'off');

% reset accuracies
accuracy_vals = getappdata(handles.figure1,'accuracy_vals');
set(handles.text1, 'String', accuracy_vals(1));
set(handles.text2, 'String', accuracy_vals(2));
set(handles.text3, 'String', accuracy_vals(3));
set(handles.text4, 'String', accuracy_vals(4));
set(handles.text5, 'String', accuracy_vals(5));
set(handles.text6, 'String', accuracy_vals(6));
set(handles.text7, 'String', accuracy_vals(7));
set(handles.text8, 'String', accuracy_vals(8));
set(handles.text9, 'String', accuracy_vals(9));
set(handles.text10, 'String', accuracy_vals(10));
set(handles.text11, 'String', accuracy_vals(11));
set(handles.text12, 'String', accuracy_vals(12));
set(handles.text13, 'String', accuracy_vals(13));
set(handles.text14, 'String', accuracy_vals(14));
set(handles.text15, 'String', accuracy_vals(15));
set(handles.text16, 'String', accuracy_vals(16));
set(handles.text17, 'String', accuracy_vals(17));

% grab data elements
params = getappdata(handles.figure1,'params');
image_dir = getappdata(handles.figure1,'image_dir');
data_dir = getappdata(handles.figure1,'data_dir');
categories = getappdata(handles.figure1,'categories');
filenames_train = getappdata(handles.figure1,'filenames_train');
filenames_test = getappdata(handles.figure1,'filenames_test');
labels_train = getappdata(handles.figure1,'labels_train');
labels_test = getappdata(handles.figure1,'labels_test');

num_categories = length(categories);
num_images_train = length(labels_train);
num_images_test = length(labels_test);

% extract coding method
switch get(get(handles.method_group,'SelectedObject'),'Tag')
    case 'radio_llc',  useLLC = 1;
    case 'radio_spm',  useLLC = 0;
    otherwise, useLLC = 1; % default... should never happen
end
tic;
if useLLC
    addpath('lib/spatialpyramid-llc');
    % training set
    pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);
    % testing set
    pyramid_test = BuildPyramid(filenames_test, image_dir, data_dir, params, true, false);
    rmpath('lib/spatialpyramid-llc');
else
    data_dir = '../features/scene-category';
    addpath('lib/spatialpyramid');
    % training set
    pyramid_train = BuildPyramid(filenames_train, image_dir, data_dir, params, true, false);
    % testing set
    pyramid_test = BuildPyramid(filenames_test, image_dir, data_dir, params, true, false);
    rmpath('lib/spatialpyramid');
end

% train SVM and predict

addpath('lib/liblinear-1.96/matlab');
model_llc = train(labels_train, sparse(pyramid_train), '-c 10');
[labels_test_predict, accuracy, decval_llc] = predict(labels_test, sparse(pyramid_test), model_llc);
rmpath('lib/liblinear-1.96/matlab');

% compute object bank if needed
if (params.useObjectBank ~= 0)
    disp('USING OBJECT BANK! GENERATING FEATURES!');
    ob_dir = '../features/scene-category-objectbank';
    
    % extract features - Object Bank
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
    
    %train and predict object bank
    addpath('lib/liblinear-1.96/matlab');
    model_ob = train(labels_train, sparse(ob_train), '-s 6 -c 10');
    [~, ~, decval_ob] = predict(labels_test, sparse(ob_test), model_ob);
    rmpath('lib/liblinear-1.96/matlab');
    
    %combine
    decval_all = decval_llc + decval_ob;
    [~, labels_test_predict] = max(decval_all, [], 2);
    accuracy = sum(labels_test_predict==labels_test) / num_images_test * 100;
end


% setup accuracies
class_acc = nan(1,15);
for ind = 1:15
    class_ind = labels_test == ind;
    class_acc(ind) = sum( labels_test(class_ind) == labels_test_predict(class_ind) ) / sum( class_ind );
    class_acc(ind) = class_acc(ind) * 100;
    accuracy_vals{ind} = [accuracy_vals{ind} num2str(class_acc(ind),3)];
end
avg_acc = sum(class_acc) / 15;
accuracy_vals{16} = [accuracy_vals{16} num2str(avg_acc,3)];
accuracy_vals{17} = [accuracy_vals{17} num2str(accuracy(1),3)];
set(handles.text1, 'String', accuracy_vals(1));
set(handles.text2, 'String', accuracy_vals(2));
set(handles.text3, 'String', accuracy_vals(3));
set(handles.text4, 'String', accuracy_vals(4));
set(handles.text5, 'String', accuracy_vals(5));
set(handles.text6, 'String', accuracy_vals(6));
set(handles.text7, 'String', accuracy_vals(7));
set(handles.text8, 'String', accuracy_vals(8));
set(handles.text9, 'String', accuracy_vals(9));
set(handles.text10, 'String', accuracy_vals(10));
set(handles.text11, 'String', accuracy_vals(11));
set(handles.text12, 'String', accuracy_vals(12));
set(handles.text13, 'String', accuracy_vals(13));
set(handles.text14, 'String', accuracy_vals(14));
set(handles.text15, 'String', accuracy_vals(15));
set(handles.text16, 'String', accuracy_vals(16));
set(handles.text17, 'String', accuracy_vals(17));

% generate confusion matrix
[C,order] = confusionmat(labels_test,labels_test_predict);
C = C ./ repmat(sum(C, 2), 1, num_categories);
set(handles.confuse_table, 'Visible', 'on', 'Data', C);

targets = false(num_categories, num_images_test);
outputs = targets;
for i = 1 : num_images_test
    targets(labels_test(i), i) = true;
    outputs(labels_test_predict(i), i) = true;
end
h = figure;
plotconfusion(targets, outputs);
pos = get(h,'Position');
pos([3,4]) = pos([3,4]) .* 1.5;
set(h,'Position', pos, 'PaperPositionMode','auto');

% --- Executes on button press in checkbox_kmeanspp.
function checkbox_kmeanspp_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_kmeanspp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_kmeanspp
params = getappdata(handles.figure1,'params');
params.useKMeansPP = get(hObject,'Value');
setappdata(handles.figure1,'params',params);


% --- Executes on button press in checkbox_optimize.
function checkbox_optimize_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_optimize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_optimize
params = getappdata(handles.figure1,'params');
params.useCodebookOptim = get(hObject,'Value');
setappdata(handles.figure1,'params',params);

% --- Executes on selection change in popup_codesize.
function popup_codesize_Callback(hObject, eventdata, handles)
% hObject    handle to popup_codesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_codesize contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_codesize
index = get(hObject,'Value');
params = getappdata(handles.figure1,'params');
codebook_vals = getappdata(handles.figure1,'codebook_vals');
params.dictionarySize = codebook_vals(index);
setappdata(handles.figure1,'params',params);

% --- Executes during object creation, after setting all properties.
function popup_codesize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_codesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_k.
function popup_k_Callback(hObject, eventdata, handles)
% hObject    handle to popup_k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_k contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_k
index = get(hObject,'Value');
params = getappdata(handles.figure1,'params');
k_vals = getappdata(handles.figure1,'k_vals');
params.k = k_vals(index);
setappdata(handles.figure1,'params',params);

% --- Executes during object creation, after setting all properties.
function popup_k_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_objectbank.
function checkbox_objectbank_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_objectbank (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_objectbank
params = getappdata(handles.figure1,'params');
params.useObjectBank = get(hObject,'Value');
setappdata(handles.figure1,'params',params);
