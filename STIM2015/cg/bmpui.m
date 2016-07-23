function varargout = bmpui(varargin)
% BMPUI M-file for bmpui.fig
%      BMPUI, by itself, creates a new BMPUI or raises the existing
%      singleton*.
%
%      H = BMPUI returns the handle to a new BMPUI or the handle to
%      the existing singleton*.
%
%      BMPUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BMPUI.M with the given input arguments.
%
%      BMPUI('Property','Value',...) creates a new BMPUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bmpui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bmpui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help bmpui

% Last Modified by GUIDE v2.5 16-Feb-2007 19:06:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bmpui_OpeningFcn, ...
                   'gui_OutputFcn',  @bmpui_OutputFcn, ...
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


% --- Executes just before bmpui is made visible.
function bmpui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bmpui (see VARARGIN)

% Choose default command line output for bmpui
handles.output = hObject;

global EL
if EL
    POS = get(hObject, 'Position');
    set(hObject, 'Position', [250 POS(2:4)])
end

if length(varargin) > 0
    bmp = varargin{1};
    
    set(handles.T_FN, 'String', bmp.Filename);
    
    set(handles.E_Wd, 'String', num2str(bmp.w ));
    set(handles.E_Ht, 'String', num2str(bmp.h ));
    set(handles.E_Cx, 'String', num2str(bmp.cx));
    set(handles.E_Cy, 'String', num2str(bmp.cy));
    
    set(handles.E_TC, 'String', bmp.Tcol)

    
end
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes bmpui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = bmpui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

close

function E_Wd_Callback(hObject, eventdata, handles)
% hObject    handle to E_Wd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Wd as text
%        str2double(get(hObject,'String')) returns contents of E_Wd as a double


% --- Executes during object creation, after setting all properties.
function E_Wd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Wd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Ht_Callback(hObject, eventdata, handles)
% hObject    handle to E_Ht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Ht as text
%        str2double(get(hObject,'String')) returns contents of E_Ht as a double


% --- Executes during object creation, after setting all properties.
function E_Ht_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Ht (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Cx_Callback(hObject, eventdata, handles)
% hObject    handle to E_Cx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Cx as text
%        str2double(get(hObject,'String')) returns contents of E_Cx as a double


% --- Executes during object creation, after setting all properties.
function E_Cx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Cx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Cy_Callback(hObject, eventdata, handles)
% hObject    handle to E_Cy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Cy as text
%        str2double(get(hObject,'String')) returns contents of E_Cy as a double


% --- Executes during object creation, after setting all properties.
function E_Cy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Cy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Tr_Callback(hObject, eventdata, handles)
% hObject    handle to e_tc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_tc as text
%        str2double(get(hObject,'String')) returns contents of e_tc as a double


% --- Executes during object creation, after setting all properties.
function E_Tr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_tc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_Ok.
function pb_Ok_Callback(hObject, eventdata, handles)
% hObject    handle to pb_Ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    bmp.Filename = get(handles.T_FN, 'String');
    
    bmp.w = str2num(get(handles.E_Wd, 'String'));
    bmp.h = str2num(get(handles.E_Ht, 'String'));
    bmp.cx = str2num(get(handles.E_Cx, 'String'));
    bmp.cy = str2num(get(handles.E_Cy, 'String'));
    
    bmp.Tcol = get(handles.E_TC, 'String');

    handles.output = bmp;
    guidata(hObject, handles);
    
    uiresume

    
% --- Executes on button press in pb_Cancel.
function pb_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pb_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.output = [];
    guidata(hObject, handles);
    
    uiresume




function E_TG_Callback(hObject, eventdata, handles)
% hObject    handle to E_TG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_TG as text
%        str2double(get(hObject,'String')) returns contents of E_TG as a double


% --- Executes during object creation, after setting all properties.
function E_TG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_TG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_TB_Callback(hObject, eventdata, handles)
% hObject    handle to E_TB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_TB as text
%        str2double(get(hObject,'String')) returns contents of E_TB as a double


% --- Executes during object creation, after setting all properties.
function E_TB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_TB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_TC_Callback(hObject, eventdata, handles)
% hObject    handle to E_TC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_TC as text
%        str2double(get(hObject,'String')) returns contents of E_TC as a double


% --- Executes during object creation, after setting all properties.
function E_TC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_TC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


