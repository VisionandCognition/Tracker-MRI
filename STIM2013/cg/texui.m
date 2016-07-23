function varargout = texui(varargin)
% TEXUI M-file for texui.fig
%      TEXUI, by itself, creates a new TEXUI or raises the existing
%      singleton*.
%
%      H = TEXUI returns the handle to a new TEXUI or the handle to
%      the existing singleton*.
%
%      TEXUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEXUI.M with the given input arguments.
%
%      TEXUI('Property','Value',...) creates a new TEXUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before texui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to texui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help texui

% Last Modified by GUIDE v2.5 15-Feb-2007 17:43:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @texui_OpeningFcn, ...
                   'gui_OutputFcn',  @texui_OutputFcn, ...
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


% --- Executes just before texui is made visible.
function texui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to texui (see VARARGIN)

% Choose default command line output for texui
handles.output = hObject;
global EL
if EL
    POS = get(hObject, 'Position');
    set(hObject, 'Position', [250 POS(2:4)])
end

gsd = cggetdata('gsd');
set(handles.E_W, 'String', num2str(gsd.ScreenWidth));
set(handles.E_H, 'String', num2str(gsd.ScreenHeight));

if length(varargin) > 0
    tex = varargin{1};
    
    set(handles.E_W, 'String', num2str(tex.w ));
    set(handles.E_H, 'String', num2str(tex.h ));
    
    set(handles.E_BW, 'String', num2str(tex.BarWidth ), 'Style', 'text')
    set(handles.E_BL, 'String', num2str(tex.BarLength ), 'Style', 'text')
    set(handles.E_Spx, 'String', num2str(tex.Spacex ), 'Style', 'text')
    set(handles.E_Spy, 'String', num2str(tex.Spacey ), 'Style', 'text')
    set(handles.E_PN, 'String', num2str(tex.PosNoise ), 'Style', 'text')
    set(handles.E_BO, 'String', num2str(tex.BarOrientation ), 'Style', 'text')
    set(handles.E_Rnd, 'String', num2str(tex.OrNoise), 'Style', 'text' )
    set(handles.E_FN, 'String', tex.Filename , 'Style', 'text')
    
    RGB = tex.FGcolor;
    set(handles.E_FGR, 'String', num2str(RGB(1)), 'Style', 'text')
    set(handles.E_FGG, 'String', num2str(RGB(2)), 'Style', 'text')
    set(handles.E_FGB, 'String', num2str(RGB(3)), 'Style', 'text')
    
    RGB = tex.BGcolor;
    set(handles.E_BGR, 'String', num2str(RGB(1)), 'Style', 'text')
    set(handles.E_BGG, 'String', num2str(RGB(2)), 'Style', 'text')
    set(handles.E_BGB, 'String', num2str(RGB(3)), 'Style', 'text')
    
    set(handles.E_Cx, 'String', num2str(tex.cx) )
    set(handles.E_Cy, 'String', num2str(tex.cy) )
    
    

    
end   

% Update handles structure
  guidata(hObject, handles);

% UIWAIT makes texui wait for user response (see UIRESUME)
 uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = texui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

close

function E_W_Callback(hObject, eventdata, handles)
% hObject    handle to E_W (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_W as text
%        str2double(get(hObject,'String')) returns contents of E_W as a double


% --- Executes during object creation, after setting all properties.
function E_W_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_W (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_H_Callback(hObject, eventdata, handles)
% hObject    handle to E_H (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_H as text
%        str2double(get(hObject,'String')) returns contents of E_H as a double


% --- Executes during object creation, after setting all properties.
function E_H_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_H (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BW_Callback(hObject, eventdata, handles)
% hObject    handle to E_BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BW as text
%        str2double(get(hObject,'String')) returns contents of E_BW as a double


% --- Executes during object creation, after setting all properties.
function E_BW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BL_Callback(hObject, eventdata, handles)
% hObject    handle to E_BL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BL as text
%        str2double(get(hObject,'String')) returns contents of E_BL as a double


% --- Executes during object creation, after setting all properties.
function E_BL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Spx_Callback(hObject, eventdata, handles)
% hObject    handle to E_Spx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Spx as text
%        str2double(get(hObject,'String')) returns contents of E_Spx as a double


% --- Executes during object creation, after setting all properties.
function E_Spx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Spx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Spy_Callback(hObject, eventdata, handles)
% hObject    handle to E_Spy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Spy as text
%        str2double(get(hObject,'String')) returns contents of E_Spy as a double


% --- Executes during object creation, after setting all properties.
function E_Spy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Spy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_PN_Callback(hObject, eventdata, handles)
% hObject    handle to E_PN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_PN as text
%        str2double(get(hObject,'String')) returns contents of E_PN as a double


% --- Executes during object creation, after setting all properties.
function E_PN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_PN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BO_Callback(hObject, eventdata, handles)
% hObject    handle to E_BO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BO as text
%        str2double(get(hObject,'String')) returns contents of E_BO as a double


% --- Executes during object creation, after setting all properties.
function E_BO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_FN_Callback(hObject, eventdata, handles)
% hObject    handle to E_FN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_FN as text
%        str2double(get(hObject,'String')) returns contents of E_FN as a double


% --- Executes during object creation, after setting all properties.
function E_FN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_FN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_FGR_Callback(hObject, eventdata, handles)
% hObject    handle to E_FGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_FGR as text
%        str2double(get(hObject,'String')) returns contents of E_FGR as a double


% --- Executes during object creation, after setting all properties.
function E_FGR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_FGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_FGG_Callback(hObject, eventdata, handles)
% hObject    handle to E_FGG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_FGG as text
%        str2double(get(hObject,'String')) returns contents of E_FGG as a double


% --- Executes during object creation, after setting all properties.
function E_FGG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_FGG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_FGB_Callback(hObject, eventdata, handles)
% hObject    handle to E_FGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_FGB as text
%        str2double(get(hObject,'String')) returns contents of E_FGB as a double


% --- Executes during object creation, after setting all properties.
function E_FGB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_FGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BGR_Callback(hObject, eventdata, handles)
% hObject    handle to E_BGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BGR as text
%        str2double(get(hObject,'String')) returns contents of E_BGR as a double


% --- Executes during object creation, after setting all properties.
function E_BGR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BGG_Callback(hObject, eventdata, handles)
% hObject    handle to E_BGG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BGG as text
%        str2double(get(hObject,'String')) returns contents of E_BGG as a double


% --- Executes during object creation, after setting all properties.
function E_BGG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BGG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_BGB_Callback(hObject, eventdata, handles)
% hObject    handle to E_BGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_BGB as text
%        str2double(get(hObject,'String')) returns contents of E_BGB as a double


% --- Executes during object creation, after setting all properties.
function E_BGB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_BGB (see GCBO)
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


function E_Rnd_Callback(hObject, eventdata, handles)
% hObject    handle to E_Rnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Rnd as text
%        str2double(get(hObject,'String')) returns contents of E_Rnd as a double


% --- Executes during object creation, after setting all properties.
function E_Rnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Rnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PB_OK.
function PB_OK_Callback(hObject, eventdata, handles)
% hObject    handle to PB_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    tex.w = str2num(get(handles.E_W, 'String'));
    tex.h = str2num(get(handles.E_H, 'String'));
    tex.BarWidth = str2num(get(handles.E_BW, 'String'));
    tex.BarLength = str2num(get(handles.E_BL, 'String'));
    tex.Spacex = str2num(get(handles.E_Spx, 'String'));
    tex.Spacey = str2num(get(handles.E_Spy, 'String'));
    tex.PosNoise = str2num(get(handles.E_PN, 'String'));        
    tex.BarOrientation = str2num(get(handles.E_BO, 'String'));
    tex.OrNoise = str2num(get(handles.E_Rnd, 'String'));
    
    tex.Filename = get(handles.E_FN, 'String');
    
    R = str2num(get(handles.E_FGR, 'String'));
    G = str2num(get(handles.E_FGG, 'String'));
    B = str2num(get(handles.E_FGB, 'String'));   
    tex.FGcolor = ([ R G B ]);
    R = str2num(get(handles.E_BGR, 'String'));
    G = str2num(get(handles.E_BGG, 'String'));
    B = str2num(get(handles.E_BGB, 'String'));         
    tex.BGcolor = ( [ R G B ] );
    
    tex.cx = str2num(get(handles.E_Cx, 'String'));
    tex.cy = str2num(get(handles.E_Cy, 'String'));

    handles.output = tex;
    guidata(hObject, handles);
    
    uiresume


% --- Executes on button press in PB_Cancel.
function PB_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to PB_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles.output = [];
    guidata(hObject, handles);
    
    uiresume




