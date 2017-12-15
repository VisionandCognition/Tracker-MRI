function varargout = tracker_CK(varargin)
% TRACKER_CK M-file for tracker_CK.fig
%      TRACKER_CK, by itself, creates a new TRACKER_CK or raises the existing
%      singleton*.
%
%      H = TRACKER_CK returns the handle to a new TRACKER_CK or the handle to
%      the existing singleton*.
%
%      TRACKER_CK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKER_CK.M with the given input arguments.
%
%      TRACKER_CK('Property','Value',...) creates a new TRACKER_CK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before tracker_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to tracker_CK_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help tracker_CK

% Last Modified by GUIDE v2.5 11-Jan-2016 18:10:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @tracker_CK_OpeningFcn, ...
    'gui_OutputFcn',  @tracker_CK_OutputFcn, ...
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


% --- Executes just before tracker_CK is made visible.
function tracker_CK_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tracker_CK (see VARARGIN)
% X = varargin{1};
% Y = varargin{2};
% line(X, Y)
% Choose default command line output for tracker_CK
handles.output = hObject;

Init(hObject, handles)
% ht = uitoolbar(hObject)
% a(:,:,1) = rand(20);
% a(:,:,2) = rand(20);
% a(:,:,3) = rand(20);
% htt = uitoggletool(ht,'CData',a,'TooltipString','Hello')

% Update handles structure
%guidata(hObject, handles);

% UIWAIT makes tracker_CK wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = tracker_CK_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Init.
function Init(hObject, handles)
% hObject    handle to Init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% prestim %initial values, startup of das, startup of cogent
prestim_ptb %initial values, startup of das, startup of ptb
if isfield(Par,'DasOn') && Par.DasOn %defined in prestim
    handles.DasOn = true;
end

% initialize paramaterfields
%timing
set(handles.ToFixTime, 'String', num2str(Par.Times.ToFix, 4))
set(handles.FixT, 'String', num2str(Par.Times.Fix, 4))
set(handles.StimT, 'String', num2str(Par.Times.Stim, 4))

if numel(Par.Times.Targ)==1
    set(handles.TargT, 'String', num2str(Par.Times.Targ, 4))
else 
    set(handles.TargT, 'String', num2str(Par.Times.Targ(1,2), 4))
end

set(handles.ReactionT, 'String', num2str(Par.Times.Rt, 4))
set(handles.InterTT, 'String', num2str(Par.Times.InterTrial, 4))

set(handles.e_RndFix, 'String', num2str(Par.Times.RndFix, 4))
set(handles.e_RndStim, 'String', num2str(Par.Times.RndStim, 4))
set(handles.e_RndTarg, 'String', num2str(Par.Times.RndTarg, 4))
set(handles.e_Sacc, 'String', num2str(Par.Times.Sacc, 4))
set(handles.e_Err, 'String', num2str(Par.Times.Err, 4))

if numel(Par.RewardTime)==1
    set(handles.Lbl_Rwtime, 'String', num2str(Par.RewardTime, 5))
    set(handles.slider1, 'Value', Par.RewardTime)
else
    set(handles.Lbl_Rwtime, 'String', num2str(Par.RewardTime(1,2), 5))
    set(handles.slider1, 'Value', Par.RewardTime(1,2))
end

set(handles.rb_Drum, 'Value', Par.Drum)
set(handles.E_RGB, 'String',  [ num2str(Par.BG(1)) ' ' num2str(Par.BG(2)) ' ' num2str(Par.BG(2))])

Updatetimeaxes(handles)
%scale eyeinput to pixels
set(handles.lblScx, 'String', num2str(Par.SCx, 4))
set(handles.lblScy, 'String', num2str(Par.SCy, 4))
set(handles.TB_x, 'String', ['x*' num2str(Par.xdir, 1)])
set(handles.TB_y, 'String', ['y*' num2str(Par.ydir, 1)])

%control window dimensions
set(handles.LFixWd, 'String', num2str(Par.FixWdDeg) )
set(handles.LTargWd, 'String', num2str(Par.TargWdDeg) )
set(handles.LFixHt, 'String', num2str(Par.FixHtDeg) )
set(handles.LTargHt, 'String', num2str(Par.TargHtDeg) )

set(handles.ScrDist, 'String', num2str(Par.DistanceToScreen));
set(handles.ScrWid, 'String', num2str(Par.ScreenWidthD2 * 2));
set(handles.PixDeg, 'String', num2str(Par.PixPerDeg, 4));

% some hand control and fix parameters
set(handles.RewHIB,'Value',Par.RewNeeds.HandIsIn);
set(handles.StimHIB,'Value',Par.StimNeeds.HandIsIn);
set(handles.FixHIB,'Value',Par.FixNeeds.HandIsIn);
set(handles.SecFixCol,'Value',Par.RewardFixFeedBack);
set(handles.AutoDim,'Value',Par.HandOutDimsScreen);
set(handles.AutoDimPerc,'Value',Par.HandOutDimsScreen_perc);


handles.RUNFUNC = @runstim;
set(handles.T_RUN, 'String', ['Runfunction : ' Par.RUNFUNC]);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

Par.ESC = true;
%     if Par.isRunning == true
%         return
%     end
%     poststim

% --- Executes on button press in Run.
function Run_Callback(hObject, eventdata, handles)
% hObject    handle to Run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
if isfield(handles, 'DasOn') && handles.DasOn
    set(hObject, 'BackgroundColor', [0.5 0.6 0.9])
    Par.isRunning = true;
    axes(handles.axes1);
    
    %the runfunction is now a handle, don't change!!!!!
    handles.RUNFUNC([handles.T_Trl handles.T_Sd]) %gets a handle to update trial numbers and noise value
    
end  %IS_RUNNING%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Par.isRunning = false;
set(hObject, 'BackgroundColor', [0.925 0.914 0.847])

% --- Executes on button press in ZoomUp.
function ZoomUp_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
Par.ZOOM = Par.ZOOM * 1.25;
cla
refreshtracker( 1)


% --- Executes on button press in ZoomDown.
function ZoomDown_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
Par.ZOOM = Par.ZOOM * 0.8;
cla
refreshtracker( 1)



% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

Par.KeyDetectedInTrackerWindow = true;
KP = double(get(hObject, 'CurrentCharacter'));
%ST = get(hObject, 'SelectionType');
%disp(ST) %works with mouse buttons!!!!left = 'normal', middle = 'extend',
%right = 'alt'
% if strcmp(ST,'normal')
%     Par.MousePress = 0;
%     set(handles.rb_SCALE, 'Value', 1.0);
% elseif strcmp(ST,'alt')
%     Par.MousePress = 2;
%     set(handles.rb_SHIFT, 'Value', 1.0);
% end


if ~isempty(KP)
    switch KP
        case 28  %left arrow was pressed
            if Par.MousePress == 2
                %Par.OFFx = Par.OFFx - 1 * Par.xdir;
                %calllib(Par.Dll, 'ShiftOffset', -1, 0);
                Par.ScaleOff = dasoffset( -1, 0);
            else
                Par.SCx = Par.SCx * 1/1.1;
                set(handles.lblScx, 'String', num2str(Par.SCx, 4))
                Par.ScaleOff(3) = Par.SCx;
            end
            %disp('keypress left')
        case 29  %Right arrow was pressed
            if Par.MousePress == 2
                %Par.OFFx = Par.OFFx + 1 * Par.xdir;
                %calllib(Par.Dll, 'ShiftOffset', 1, 0);
                Par.ScaleOff = dasoffset( 1, 0);
            else
                Par.SCx = Par.SCx * 1.1;
                set(handles.lblScx, 'String', num2str(Par.SCx, 4))
                Par.ScaleOff(3) = Par.SCx;
            end
            % disp('keypress right')
        case 30  %up arrow was pressed
            if Par.MousePress == 2
                %Par.OFFy = Par.OFFy + 1 * Par.ydir;
                %calllib(Par.Dll, 'ShiftOffset', 0, 1);
                Par.ScaleOff = dasoffset( 0, 1);
            else
                Par.SCy = Par.SCy * 1.1;
                set(handles.lblScy, 'String', num2str(Par.SCy, 4))
                Par.ScaleOff(4) = Par.SCy;
            end
            %disp('keypress up')
        case 31  %down arrow was pressed
            if Par.MousePress == 2
                % Par.OFFy = Par.OFFy - 1 * Par.ydir;
                %calllib(Par.Dll, 'ShiftOffset', 0, -1);
                Par.ScaleOff = dasoffset( 0, -1);
            else
                Par.SCy = Par.SCy * 1/1.1;
                set(handles.lblScy, 'String', num2str(Par.SCy, 4))
                Par.ScaleOff(4) = Par.SCy;
            end
            % disp('keypress down')
        case 27  %escape key was pressed
            Par.ESC = 1;
            % disp('keypress ESC')
        case 122 %Z key was pressed
            % Par.SetZero = true;
            % disp('keypress ZERO')
            if Par.Mouserun
                %             LPM = calllib(Par.Dll, 'Use_Mouse', Par.Mouserun );
                %             setdatatype(LPM, 'int32Ptr', 2, 1);
                Par.MOff = dasusemouse( 1 );
            else
                %calllib(Par.Dll,'SetZero');
                Par.ScaleOff = daszero();
            end
        %case 106 %j key was pressed , give juice reward
            % %         calllib(Par.Dll, 'DO_Bit', Par.RewardB, 1);
            % %         calllib(Par.Dll, 'Juice', 3.5);
            %         dasbit( Par.RewardB, 1);
            %         dasjuice( 4 );
            %         pause(Par.RewardTime)
            % %         calllib(Par.Dll, 'DO_Bit', Par.RewardB, 0);
            % %         calllib(Par.Dll, 'Juice', 0.0);
            %         dasbit( Par.RewardB, 0);
            %         dasjuice( 0 );
            %         disp('Reward')
        otherwise
            %disp(KP)
    end
    
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global Par
Par.RewardTime = get(hObject,'Value');
set(handles.Lbl_Rwtime, 'String', num2str(Par.RewardTime, '% -5.3f'));

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --------------------------------------------------------------------
function READ_Callback(hObject, eventdata, handles)
% hObject    handle to READ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

RUNFUNC = '';

[FileName,PathName] = uigetfile('PAR.mat','Select a parameter Mat-file','PAR.mat');
Pf = fullfile(PathName,FileName);

if exist(Pf)
    load(Pf)
    Par.Times = Times;
    Par.Drum = Drum;
    
    Par.SCx = SCx;
    Par.SCy = SCy;
    
    Par.DistanceToScreen = DistanceToScreen;
    Par.ScreenWidthD2 = ScreenWidthD2;
    Par.PixPerDeg = PixPerDeg;
    Par.FixWdDeg = FixWdDeg;
    Par.TargWdDeg = TargWdDeg;
    Par.FixHtDeg = FixHtDeg;
    Par.TargHtDeg = TargHtDeg;
    Par.xdir = xdir;
    Par.ydir = ydir;
    
    Par.BG = BG;
    
    if exist(RUNFUNC, 'var')
        Par.RUNFUNC = RUNFUNC;
        
        handles.RUNFUNC = str2fun(Par.RUNFUNC);
        set(handles.T_RUN, 'String', ['Runfunction : ' Par.RUNFUNC]);
    end
    
    set(handles.ToFixTime, 'String', num2str(Times.ToFix, 4));
    set(handles.FixT, 'String', num2str(Times.Fix, 4));
    set(handles.StimT, 'String', num2str(Times.Stim, 4));
    
    %set(handles.TargT, 'String', num2str(Times.Targ, 4));
    if numel(Par.Times.Targ)==1
        set(handles.TargT, 'String', num2str(Par.Times.Targ, 4))
    else
        set(handles.TargT, 'String', num2str(Par.Times.Targ(1,2), 4))
    end
    
    set(handles.ReactionT, 'String', num2str(Par.Times.Rt, 4))
    set(handles.InterTT, 'String', num2str(Times.InterTrial, 4));
    Updatetimeaxes(handles) %update axes showing control times
    
    set(handles.e_RndFix, 'String', num2str(Par.Times.RndFix, 4))
    set(handles.e_RndStim, 'String', num2str(Par.Times.RndStim, 4))
    set(handles.e_RndTarg, 'String', num2str(Par.Times.RndTarg, 4))
    set(handles.e_Sacc, 'String', num2str(Par.Times.Sacc, 4))
    set(handles.e_Err, 'String', num2str(Par.Times.Err, 4))
    
    set(handles.rb_Drum, 'Value', Par.Drum)
    set(handles.E_RGB, 'String',  [ num2str(Par.BG(1)) ' ' num2str(Par.BG(2)) ' ' num2str(Par.BG(2))])
    
    set(handles.lblScx, 'String', num2str(Par.SCx, 4));
    set(handles.lblScy, 'String', num2str(Par.SCy, 4));
    set(handles.TB_x, 'String', ['x*' num2str(Par.xdir, 1)])
    set(handles.TB_y, 'String', ['y*' num2str(Par.ydir, 1)])
    
    %control window dimensions
    set(handles.LFixWd, 'String', num2str(Par.FixWdDeg) )
    set(handles.LTargWd, 'String', num2str(Par.TargWdDeg) )
    set(handles.LFixHt, 'String', num2str(Par.FixHtDeg) )
    set(handles.LTargHt, 'String', num2str(Par.TargHtDeg) )
    
    set(handles.ScrDist, 'String', num2str(Par.DistanceToScreen));
    set(handles.ScrWid, 'String', num2str(Par.ScreenWidthD2 * 2));
    set(handles.PixDeg, 'String', num2str(Par.PixPerDeg, 4));
    
    % some hand control and fix parameters
    set(handles.RewHIB,'Value',Par.RewNeeds.HandIsIn);
    set(handles.StimHIB,'Value',Par.StimNeeds.HandIsIn);
    set(handles.FixHIB,'Value',Par.FixNeeds.HandIsIn);
    set(handles.SecFixCol,'Value',Par.RewardFixFeedBack);
    set(handles.AutoDim,'Value',Par.HandOutDimsScreen);
    set(handles.AutoDimPerc,'Value',Par.HandOutDimsScreen_perc);
    
    %     FixSz = Par.FixSzDeg * Par.PixPerDeg;
    %     TargSz = Par.TargSzDeg * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 0 %fix window == 0
            Par.WIN(3,i) = Par.FixHtDeg * Par.PixPerDeg; %width
            Par.WIN(4,i) = Par.FixWdDeg * Par.PixPerDeg; %height
            
        elseif Par.WIN(5,i) == 1 || Par.WIN(5,i) == 2 %target window == 2
            Par.WIN(3,i) = Par.TargHtDeg * Par.PixPerDeg; %width
            Par.WIN(4,i) = Par.TargWdDeg * Par.PixPerDeg; %height
        end
    end
    
    guidata(hObject, handles);
else
    errordlg('No saved Parameters to retrieve')
end
% --------------------------------------------------------------------
function SAVE_Callback(hObject, eventdata, handles)
% hObject    handle to SAVE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

save( 'PAR.mat', '-struct', 'Par')

% --------------------------------------------------------------------
function SAVEAS_Callback(hObject, eventdata, handles)
% hObject    handle to SAVEAS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Par


[file,path] = uiputfile('PAR.mat','Save PAR as');
if file ~= 0
    save([path file], '-struct', 'Par')
else
    errormsg('No filename supplied')
end





% --------------------------------------------------------------------
function CHANGE_Callback(hObject, eventdata, handles)
% hObject    handle to CHANGE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.axes1, 'Visible', 'off')
CHILD = get(handles.axes1, 'Children');
for i = 1:length(CHILD)
    set(CHILD(i), 'Visible', 'off')
end
set(handles.ParmPanel, 'Visible', 'on')
Updatetimeaxes(handles) %update axes showing control times

% --- Executes on button press in ParmClose.
function ParmClose_Callback(hObject, eventdata, handles)
% hObject    handle to ParmClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.ParmPanel, 'Visible', 'off')

refreshtracker( 1)
set(handles.axes1, 'Visible', 'on')
%   CHILD = get(handles.axes1, 'Children');
%   for i = 1:length(CHILD)
%      set(CHILD(i), 'Visible', 'on')
%   end


function ToFixTime_Callback(hObject, eventdata, handles)
% hObject    handle to ToFixTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ToFixTime as text
%        str2double(get(hObject,'String')) returns contents of ToFixTime as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time == 0
    errordlg('Enter valid time')
else
    Par.Times.ToFix = time;
end
Updatetimeaxes(handles)

% --- Executes during object creation, after setting all properties.
function ToFixTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ToFixTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FixT_Callback(hObject, eventdata, handles)
% hObject    handle to FixT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FixT as text
%        str2double(get(hObject,'String')) returns contents of FixT as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time == 0
    errordlg('Enter valid time')
else
    Par.Times.Fix = time;
end
Updatetimeaxes(handles)

% --- Executes during object creation, after setting all properties.
function FixT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FixT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StimT_Callback(hObject, eventdata, handles)
% hObject    handle to StimT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StimT as text
%        str2double(get(hObject,'String')) returns contents of StimT as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time <= 0
    errordlg('Enter valid time')
else
    Par.Times.Stim = round(round(time/Par.fliptime)*Par.fliptime);
    set(hObject,'String', num2str(Par.Times.Stim) )
end
Updatetimeaxes(handles)

% --- Executes during object creation, after setting all properties.
function StimT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StimT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TargT_Callback(hObject, eventdata, handles)
% hObject    handle to TargT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargT as text
%        str2double(get(hObject,'String')) returns contents of TargT as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time < 0
    errordlg('Enter valid time')
else
    Par.Times.Targ = round(round(time/Par.fliptime)*Par.fliptime);
    set(hObject,'String', num2str(Par.Times.Targ) )
    
end
Updatetimeaxes(handles)

% --- Executes during object creation, after setting all properties.
function TargT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TargT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ReactionT_Callback(hObject, eventdata, handles)
% hObject    handle to ReactionT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ReactionT as text
%        str2double(get(hObject,'String')) returns contents of ReactionT as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time <= 0
    errordlg('Enter valid time')
else
    Par.Times.Rt = time;
end
Updatetimeaxes(handles)


% --- Executes during object creation, after setting all properties.
function ReactionT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ReactionT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function InterTT_Callback(hObject, eventdata, handles)
% hObject    handle to InterTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of InterTT as text
%        str2double(get(hObject,'String')) returns contents of InterTT as a double
global Par
time = str2double(get(hObject,'String'));
if isnan(time) || time < 0
    errordlg('Enter valid time')
else
    Par.Times.InterTrial = time;
end
Updatetimeaxes(handles)

% --- Executes during object creation, after setting all properties.
function InterTT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InterTT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in juiceradio.
function juiceradio_Callback(hObject, eventdata, handles)
% hObject    handle to juiceradio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of juiceradio
global Par

Par.Reward = get(hObject,'Value');



function lblScx_Callback(hObject, eventdata, handles)
% hObject    handle to lblScx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lblScx as text
%        str2double(get(hObject,'String')) returns contents of lblScx as a double


% --- Executes during object creation, after setting all properties.
function lblScx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblScx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LblScy_Callback(hObject, eventdata, handles)
% hObject    handle to LblScy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LblScy as text
%        str2double(get(hObject,'String')) returns contents of LblScy as a double


% --- Executes during object creation, after setting all properties.
function LblScy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LblScy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lblScy_Callback(hObject, eventdata, handles)
% hObject    handle to lblScy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lblScy as text
%        str2double(get(hObject,'String')) returns contents of lblScy as a double


% --- Executes during object creation, after setting all properties.
function lblScy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lblScy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function LFixx_Callback(hObject, eventdata, handles)
% hObject    handle to LFixx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LFixx as text
%        str2double(get(hObject,'String')) returns contents of LFixx as a double


% --- Executes during object creation, after setting all properties.
function LFixx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LFixx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LTargx_Callback(hObject, eventdata, handles)
% hObject    handle to LTargx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LTargx as text
%        str2double(get(hObject,'String')) returns contents of LTargx as a double


% --- Executes during object creation, after setting all properties.
function LTargx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LTargx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LFixy_Callback(hObject, eventdata, handles)
% hObject    handle to LFixy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LFixy as text
%        str2double(get(hObject,'String')) returns contents of LFixy as a double


% --- Executes during object creation, after setting all properties.
function LFixy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LFixy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LTargy_Callback(hObject, eventdata, handles)
% hObject    handle to LTargy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LTargy as text
%        str2double(get(hObject,'String')) returns contents of LTargy as a double


% --- Executes during object creation, after setting all properties.
function LTargy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LTargy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LFixWd_Callback(hObject, eventdata, handles)
% hObject    handle to LFixWd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LFixWd as text
global Par
Val = str2double(get(hObject,'String')); %returns contents of LFixSz as a double
if ~isnan(Val) && Val > 0
    Par.FixWdDeg = Val;
    FixWd = Val * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 0 %fix window == 0
            Par.WIN(3,i) = FixWd; %width
        end
    end
end


% --- Executes during object creation, after setting all properties.
function LFixWd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LFixWd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LTargWd_Callback(hObject, eventdata, handles)
% hObject    handle to LTargWd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LTargWd as text
%        str2double(get(hObject,'String')) returns contents of LTargWd as a double
global Par
Val = str2double(get(hObject,'String')); %returns contents of LFixSz as a double
if ~isnan(Val) && Val > 0
    Par.TargWdDeg = Val;
    TargWd = Val * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 1 || Par.WIN(5,i) == 2 %target window == 2
            Par.WIN(3,i) = TargWd; %width
        end
    end
end


% --- Executes during object creation, after setting all properties.
function LTargWd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LTargWd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LFixHt_Callback(hObject, eventdata, handles)
% hObject    handle to LFixHt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LFixHt as text
%        str2double(get(hObject,'String')) returns contents of LFixHt as a double
global Par
Val = str2double(get(hObject,'String')); %returns contents of LFixSz as a double
if ~isnan(Val) && Val > 0
    Par.FixHtDeg = Val;
    FixHt = Val * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 0 %fix window == 0
            Par.WIN(4,i) = FixHt; %width
        end
    end
end



% --- Executes during object creation, after setting all properties.
function LFixHt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LFixHt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LTargHt_Callback(hObject, eventdata, handles)
% hObject    handle to LTargHt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LTargHt as text
%        str2double(get(hObject,'String')) returns contents of LTargHt as a double

global Par
Val = str2double(get(hObject,'String')); %returns contents of LFixSz as a double
if ~isnan(Val) && Val > 0
    Par.TargHtDeg = Val;
    TargHt = Val * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 1 || Par.WIN(5,i) == 2 %target window == 2
            Par.WIN(4,i) = TargHt; %width
        end
    end
end


% --- Executes during object creation, after setting all properties.
function LTargHt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LTargHt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ScrDist_Callback(hObject, eventdata, handles)
% hObject    handle to ScrDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScrDist as text
%        str2double(get(hObject,'String')) returns contents of ScrDist as a double
global Par
Val = str2double(get(hObject,'String')); %returns contents as a double
if ~isnan(Val) && Val > 0
    Par.DistanceToScreen = Val;
    Par.PixPerDeg = Par.HW/atand(Par.ScreenWidthD2/Val);
    set(handles.PixDeg, 'String', num2str(Par.PixPerDeg) )
    
    
    %         TargSz = Par.TargSzDeg * Par.PixPerDeg;
    %         FixSz = Par.FixSzDeg * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 0 %fix window == 0
            Par.WIN(3,i) = Par.FixWdDeg * Par.PixPerDeg; %width
            Par.WIN(4,i) = Par.FixHtDeg * Par.PixPerDeg; %height
            
        elseif Par.WIN(5,i) == 1 || Par.WIN(5,i) == 2 %target window == 2
            Par.WIN(3,i) = Par.TargWdDeg * Par.PixPerDeg; %width
            Par.WIN(4,i) = Par.TargHtDeg * Par.PixPerDeg; %heigth
        end
    end
    
    
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function ScrDist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScrDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ScrWid_Callback(hObject, eventdata, handles)
% hObject    handle to ScrWid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScrWid as text
%        str2double(get(hObject,'String')) returns contents of ScrWid as a double
global Par

Val = str2double(get(hObject,'String')); %returns contents as a double
if ~isnan(Val) && Val > 0
    Par.ScreenWidthD2 = Val/2;
    Par.PixPerDeg = Par.HW/atand(Par.ScreenWidthD2/Par.DistanceToScreen);
    set(handles.PixDeg, 'String', num2str(Par.PixPerDeg) )
    
    %         TargSz = Par.TargSzDeg * Par.PixPerDeg;
    %         FixSz = Par.FixWdDeg * Par.PixPerDeg;
    for i = 1:size(Par.WIN,2)
        if Par.WIN(5,i) == 0 %fix window == 0
            Par.WIN(3,i) = Par.FixWdDeg * Par.PixPerDeg; %width
            Par.WIN(4,i) = Par.FixHtDeg * Par.PixPerDeg;%height
        elseif Par.WIN(5,i) == 1 || Par.WIN(5,i) == 2 %target window == 2
            Par.WIN(3,i) = Par.TargWdDeg * Par.PixPerDeg;  %width
            Par.WIN(4,i) = Par.TargHtDeg * Par.PixPerDeg;
        end
    end
    
    
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function ScrWid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScrWid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function PixDeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PixDeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Updatetimeaxes(handles)

global Par
axes(handles.axes_timing);
cla
Times = Par.Times;

plot([-(Times.ToFix + Times.Fix)  -Times.Fix], [0 0], 'Color', [0.75 0.75 0.75], 'LineWidth', 10)
hold on

if numel(Par.Times.Targ)==1
    set(handles.TargT, 'String', num2str(Par.Times.Targ, 4))
else 
    set(handles.TargT, 'String', num2str(Par.Times.Targ(1,2), 4))
end

if numel(Par.Times.Targ)==1
    plot([ -Times.Fix Times.Targ], [0 0], 'LineWidth', 10, 'Color', [0 0.75 0.75])
    plot([Times.Targ Times.Targ + Par.Times.Rt], [0 0], 'LineWidth', 10, 'Color', [0.75 0.75 0])
    plot([Times.Targ + Par.Times.Rt Times.Targ + Par.Times.Rt+Times.InterTrial], ...
        [0 0], 'Color', [0.5 0.5 0.5], 'LineWidth', 10)
else
    plot([ -Times.Fix Times.Targ(1,2)], [0 0], 'LineWidth', 10, 'Color', [0 0.75 0.75])
    plot([Times.Targ(1,2) Times.Targ(1,2) + Par.Times.Rt], [0 0], 'LineWidth', 10, 'Color', [0.75 0.75 0])
    plot([Times.Targ(1,2) + Par.Times.Rt Times.Targ(1,2) + Par.Times.Rt+Times.InterTrial], ...
        [0 0], 'Color', [0.5 0.5 0.5], 'LineWidth', 10)
end


plot([ 0 Times.Stim], [0 0], 'k', 'LineWidth', 5)

line([-Times.Fix -Times.Fix], [-0.1 1])
text(-Times.Fix, 0.2, 'Fix')
line([0 0], [-0.1 1])
text(0, 0.4, 'Stim')

if numel(Par.Times.Targ)==1
    line([Times.Targ Times.Targ], [-0.1 1])
    text(Times.Targ, 0.6, 'Targ')
else
    line([Times.Targ(1,2) Times.Targ(1,2)], [-0.1 1])
    text(Times.Targ(1,2), 0.6, 'Targ')
end

% POS = get(handles.figure1, 'Position');
lgnd1 = legend('Fix\_wait duration', 'Fixation time', 'Reaction time', 'Intertrial time', 'Stim\_on time');
set(lgnd1,'Units','characters','Position', [5 14 30 8]);
xlabel('time(ms)')
set(handles.axes_timing, 'YLim', [-0.1 1])
set(handles.axes_timing, 'YTick', [], 'YTickLabel', '')

axes(handles.axes1);


% --------------------------------------------------------------------
function M_Con_Callback(hObject, eventdata, handles)
% hObject    handle to M_Con (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function I_Bezier_Callback(hObject, eventdata, handles)
% hObject    handle to I_Bezier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in RB_Sqr.
function RB_Sqr_Callback(hObject, eventdata, handles)
% hObject    handle to RB_Sqr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RB_Sqr
global Par
Par.Bsqr = get(hObject,'Value');

function e_RndFix_Callback(hObject, eventdata, handles)
% hObject    handle to e_RndFix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_RndFix as text
%        str2double(get(hObject,'String')) returns contents of e_RndFix as a double
global Par
Val = str2double(get(hObject,'String'));
if ~isnan(Val)
    Par.Times.RndFix = Val;
else
    errordlg('Invalid  input');
end


% --- Executes during object creation, after setting all properties.
function e_RndFix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_RndFix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function e_RndStim_Callback(hObject, eventdata, handles)
% hObject    handle to e_RndStim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_RndStim as text
%        str2double(get(hObject,'String')) returns contents of e_RndStim as a double
global Par
Val = str2double(get(hObject,'String'));
if ~isnan(Val) && Val >= 0
    Par.Times.RndStim = Val;
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function e_RndStim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_RndStim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function e_RndTarg_Callback(hObject, eventdata, handles)
% hObject    handle to e_RndTarg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_RndTarg as text
%        str2double(get(hObject,'String')) returns contents of e_RndTarg as a double
global Par
Val = str2double(get(hObject,'String'));
if ~isnan(Val) && Val >= 0
    Par.Times.RndTarg = Val;
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function e_RndTarg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_RndTarg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function e_Err_Callback(hObject, eventdata, handles)
% hObject    handle to e_Err (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_Err as text
%        str2double(get(hObject,'String')) returns contents of e_Err as a double
global Par
Val = str2double(get(hObject,'String'));
if ~isnan(Val)
    Par.Times.Err = Val;
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function e_Err_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_Err (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function e_Sacc_Callback(hObject, eventdata, handles)
% hObject    handle to e_Sacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_Sacc as text
%        str2double(get(hObject,'String')) returns contents of e_Sacc as a double
global Par
Val = str2double(get(hObject,'String'));
if ~isnan(Val)
    Par.Times.Sacc = Val;
else
    errordlg('Invalid  input');
end

% --- Executes during object creation, after setting all properties.
function e_Sacc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_Sacc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rb_Drum.
function rb_Drum_Callback(hObject, eventdata, handles)
% hObject    handle to rb_Drum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

Par.Drum = get(hObject,'Value'); %returns toggle state of rb_Drum




% --- Executes on button press in PB_Test.
function PB_Test_Callback(hObject, eventdata, handles)
% hObject    handle to PB_Test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
if isfield(handles, 'DasOn') && handles.DasOn
    set(hObject, 'BackgroundColor', [0.5 0.6 0.9])
    Par.isRunning = true;
    axes( handles.axes1);
    
    Par.ESC = false; %escape has not been pressed
    Par.Updatxy = 1;
    while ~Par.ESC
        pause(0.05)
        DasCheck; %retrieve position values and plot on Control display
    end
    Par.Updatxy = 0;
end
Par.isRunning = false;
set(hObject, 'BackgroundColor', [0.925 0.914 0.847])

% --- Executes on button press in TB_x.
function TB_x_Callback(hObject, eventdata, handles)
% hObject    handle to TB_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TB_x
global Par
if Par.xdir == 1
    Par.xdir = -1;
else
    Par.xdir = 1;
end
set(hObject, 'String', ['x*' num2str(Par.xdir, 1)])


% --- Executes on button press in TB_y.
function TB_y_Callback(hObject, eventdata, handles)
% hObject    handle to TB_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TB_y
global Par
if Par.ydir == 1
    Par.ydir = -1;
else
    Par.ydir = 1;
end
set(hObject, 'String', ['y*' num2str(Par.ydir, 1)])


function E_RGB_Callback(hObject, eventdata, handles)
% hObject    handle to E_RGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_RGB as text
%        str2double(get(hObject,'String')) returns contents of E_RGB as a double
global Par
STR = get(hObject,'String');
strexp = '\d\.\d|\d(?!\d)';
RGBSTR = regexp(STR, strexp, 'match');
RGB = zeros(3,1);
if length(RGBSTR) == 3
    for i = 1:3
        RGB(i) = str2double(RGBSTR{i});
        if RGB(i) > 1.0 || RGB(i) < 0.0
            errordlg('Invalid input')
            return
        end
    end
    Par.BG = RGB;
else
    errordlg('Invalid input')
end


% --- Executes during object creation, after setting all properties.
function E_RGB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_RGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in rb_SCALE.
function rb_SCALE_Callback(hObject, eventdata, handles)
% hObject    handle to rb_SCALE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_SCALE
global Par
Par.MousePress = 0;



% --- Executes on button press in rb_SHIFT.
function rb_SHIFT_Callback(hObject, eventdata, handles)
% hObject    handle to rb_SHIFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_SHIFT
global Par
Par.MousePress = 2;


% --------------------------------------------------------------------
function EXIT_Callback(hObject, eventdata, handles)
% hObject    handle to EXIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
global Control

if Par.isRunning == true
    
    button = questdlg('Did your runstim crash','Alert','Yes');
    if strcmp(button, 'Yes')
        Par.isRunning = false;
        %poststim
        poststim_ptb
        delete(handles.figure1);
    end
    
else
    poststim_ptb
    %delete(handles.figure1);
    %poststim
end

% --------------------------------------------------------------------
function MI_Stim_Callback(hObject, eventdata, handles)
% hObject    handle to MI_Stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SG = Stimgui;
PS = get(SG, 'Position');
FPos = get(handles.figure1, 'Position');
% SPos =  get(handles.figure1, 'Position');
PS = [FPos(1)+10  PS(2:4)];
set(SG, 'Position', PS);

% --------------------------------------------------------------------
function MI_MonkeName_Callback(hObject, eventdata, handles)
% hObject    handle to MI_MonkeyName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
FSTR = uigetfile('*.m');
StrPth = which(FSTR);
if strcmp(StrPth, '')
    errordlg('This function is not in the matlab path')
else
    button =  questdlg({StrPth, '',  'Is this the function you want to use.?'},'Confirm');
    if  strcmp(button, 'Yes')
        Str = regexp(FSTR, '\w*', 'match');
        Par.RUNFUNC = Str{1};
        handles.RUNFUNC = str2func(Par.RUNFUNC);
        % Update handles structure
        guidata(hObject, handles);
        set(handles.T_RUN, 'String', Par.RUNFUNC);
    end
end


% --------------------------------------------------------------------
function MI_ExpFolder_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ExpFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

% go to root folder
cd(Par.StartFolder);

% remove current folders from path
OldExpFolder = Par.ExpFolder;
Par.ExpFolder=0;

% get new folder
cd TRACKER_PTB
while ~Par.ExpFolder
    Par.ExpFolder=uigetdir(pwd,...
        'Choose your experiment root-folder (contains Engine & Experiment folders)');
end

warning off
rmpath(genpath(OldExpFolder));
warning on

% close tracker
close(Par.hTracker);
% Add stuff to the path
addpath(genpath(Par.ExpFolder));
% Go to folder
cd(Par.ExpFolder);
% Run tracker
Par.hTracker=tracker_CK;


% --------------------------------------------------------------------
function MI_StimSettings_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ExpFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

% go to Exp folder
cd Experiment
cd StimSettings
% get StimSettings file
StimSetSel=false;
while ~exist('FSTR') || ~StimSetSel
    FSTR = uigetfile('*.m','Choose a StimSettings file');
    if FSTR
        StimSetSel=true;
    end
end
StrPth = which(FSTR);
cd ..
cd ..
if strcmp(StrPth, '')
    errordlg('This file is not in the matlab path')
else
    button =  questdlg({StrPth, '',  'Is this the file you want to use?'},'Confirm');
    if  strcmp(button, 'Yes')
        Str = regexp(FSTR, '\w*', 'match');
        Par.STIMSETFILE = Str{1};
    end
end

% --------------------------------------------------------------------
function MI_MonkeyName_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ExpFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

%get the monkeyname
FSTR = inputdlg('Specify monkey name','Monkey Name',1,{Par.MONKEY});
Par.MONKEY = FSTR{1};

% --------------------------------------------------------------------
function MI_ParSettings_Callback(hObject, eventdata, handles)
% hObject    handle to MI_ExpFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

% go to Exp folder
cd Experiment
cd ParSettings
% get ParSettings file
ParSetSel=false;
while ~exist('FSTR') || ~ParSetSel
    FSTR = uigetfile('*.m','Choose a ParSettings file');
    if FSTR
        ParSetSel=true;
    end
end
StrPth = which(FSTR);
cd ..
cd ..
if strcmp(StrPth, '')
    errordlg('This file is not in the matlab path')
else
    button =  questdlg({StrPth, '',  'Is this the file you want to use?'},'Confirm');
    if  strcmp(button, 'Yes')
        Str = regexp(FSTR, '\w*', 'match');
        Par.PARSETFILE = Str{1};
    end
end


% --------------------------------------------------------------------
function UPDATE_Callback(hObject, eventdata, handles)
% hObject    handle to UPDATE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pad = which( 'Trackerupdates.html');
web(pad)


% --- Executes on button press in Mouse.
function Mouse_Callback(hObject, eventdata, handles)
% hObject    handle to Mouse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Par
val = get(hObject, 'Value');
if(val >= 1)
    Par.Mouserun = 1;
    
    % set(hObject, 'Value', 0);
else
    Par.Mouserun = 0;
    % calllib(Par.Dll, 'Use_Mouse', 0);
    dasusemouse( 0 );
    %  set(hObject, 'Value', 1);
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%delete(hObject);
%     global Par
%
%     if Par.isRunning == true
%         errordlg('Please stop running first')
%         return
%     end
%     poststim
%     delete(hObject);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%     global Par
%
%     if Par.isRunning == true
%         errordlg('Please stop running first')
%         return
%     end
%     poststim
%     delete(hObject);



% --- Executes on button press in OnOFF_noise.
function OnOFF_noise_Callback(hObject, eventdata, handles)
% hObject    handle to OnOFF_noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Par

if Par.NoiseUpdate == 1
    Par.NoiseUpdate = 0;
    dassetnoise(0)
    set(hObject, 'BackgroundColor', [0.83 0.82 0.78])
else
    Par.NoiseUpdate = 1;
    dassetnoise(1)
    set(hObject, 'BackgroundColor', [1.0 0.95 0.87])
end




% --- Executes on button press in RewHIB.
function RewHIB_Callback(hObject, eventdata, handles)
% hObject    handle to RewHIB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
% Hint: get(hObject,'Value') returns toggle state of RewHIB
if get(hObject,'Value') == true
    Par.RewNeedsHandInBox = true;
else
    Par.RewNeedsHandInBox = false;
end

% --- Executes on button press in StimHIB.
function StimHIB_Callback(hObject, eventdata, handles)
% hObject    handle to StimHIB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
% Hint: get(hObject,'Value') returns toggle state of StimHIB
if get(hObject,'Value') == true
    Par.StimNeedsHandInBox = true;
else
    Par.StimNeedsHandInBox = false;
end

% --- Executes on button press in FixHIB.
function FixHIB_Callback(hObject, eventdata, handles)
% hObject    handle to FixHIB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
% Hint: get(hObject,'Value') returns toggle state of FixHIB
if get(hObject,'Value') == true
    Par.FixNeedsHandInBox = true;
else
    Par.FixNeedsHandInBox = false;
end

% --- Executes on button press in SecFixCol.
function SecFixCol_Callback(hObject, eventdata, handles)
% hObject    handle to SecFixCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
% Hint: get(hObject,'Value') returns toggle state of SecFixCol
if get(hObject,'Value') == true
    Par.RewardFixFeedBack = true;
else
    Par.RewardFixFeedBack = false;
end


% --- Executes on button press in AutoDim.
function AutoDim_Callback(hObject, eventdata, handles)
% hObject    handle to AutoDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par
% Hint: get(hObject,'Value') returns toggle state of SecFixCol
if get(hObject,'Value') == true
    Par.HandOutDimsScreen = true;
else
    Par.HandOutDimsScreen = false;
end



function AutoDimPerc_Callback(hObject, eventdata, handles)
% hObject    handle to AutoDimPerc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Par

% Hints: get(hObject,'String') returns contents of AutoDimPerc as text
%        str2double(get(hObject,'String')) returns contents of AutoDimPerc as a double
Val = str2double(get(hObject,'String'));
Par.HandOutDimsScreen_perc = Val;

% --- Executes during object creation, after setting all properties.
function AutoDimPerc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AutoDimPerc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
