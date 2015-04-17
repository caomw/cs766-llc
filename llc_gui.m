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
params.useObjectBank = 0;
params.dictionarySize = codebook_vals(4);

% save params
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

% grab data elements
params = getappdata(handles.figure1,'params');
image_dir = getappdata(handles.figure1,'image_dir');
data_dir = getappdata(handles.figure1,'data_dir');
categories = getappdata(handles.figure1,'categories');
filenames_train = getappdata(handles.figure1,'filenames_train');
filenames_test = getappdata(handles.figure1,'filenames_test');
labels_train = getappdata(handles.figure1,'labels_train');
labels_test = getappdata(handles.figure1,'labels_test');

% extract coding method
switch get(get(handles.method_group,'SelectedObject'),'Tag')
    case 'radio_llc',  useLLC = 1;
    case 'radio_spm',  useLLC = 0;
    otherwise, useLLC = 1; % default... should never happen
end

params
useLLC

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
