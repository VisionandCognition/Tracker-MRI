function varargout = Stimgui(varargin)
% STIMGUI M-file for Stimgui.fig
%      STIMGUI, by itself, creates a new STIMGUI or raises the existing
%      singleton*.
%
%      H = STIMGUI returns the handle to a new STIMGUI or the handle to
%      the existing singleton*.
%
%      STIMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STIMGUI.M with the given input arguments.
%
%      STIMGUI('Property','Value',...) creates a new STIMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Stimgui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Stimgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Stimgui

% Last Modified by GUIDE v2.5 28-Mar-2013 13:51:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Stimgui_OpeningFcn, ...
                   'gui_OutputFcn',  @Stimgui_OutputFcn, ...
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


% --- Executes just before Stimgui is made visible.
function Stimgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Stimgui (see VARARGIN)

% Choose default command line output for Stimgui
%set(hObject, 'Position', [ -100   42   63   10])
handles.output = hObject;
warning('off','MATLAB:dispatcher:InexactMatch')
if -2 == cgflip
    cgloadlib
    Mon = get(0,'MonitorPosition');
    if size(Mon,1) > 1
        cgopen(3,0,0,2)
    else  %if there is only one monitor!!!
       cgopen(3,0,0,0)
    end
end

handles.Backgroundcolor = [0 0 0]; 
%Update handles structure
guidata(hObject, handles);

 
% UIWAIT makes Stimgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Stimgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

    varargout{1} = handles.output;



% --------------------------------------------------------------------
function I_New_G_Callback(hObject, eventdata, handles)
% hObject    handle to I_New_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%     [Selection,ok] = listdlg('ListString', {'Bezier', 'Dot', 'Movingbar', 'Figure_ground'}, ...
%         'SelectionMode', 'single', 'Name', 'Create object');
%     
%     HF = figure('Position', [100 700 200 120], 'MenuBar', 'none', 'NumberTitle', 'off', 'name', 'Create object');
%     h1 = uicontrol(HF, 'style', 'listbox', 'string', {'Bezier', 'Dot', 'Movingbar', 'Figure_ground'}, ...
%         'Position', [10 10 100 100]);
%     
%     h2 = uicontrol(HF, 'style', 'pushbutton', 'string', 'Ok', 'Position', [120 10 50 20], 'callback', {@CB_done, h1});

    
 


% --------------------------------------------------------------------
function I_Save_Callback(hObject, eventdata, handles)
% hObject    handle to I_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  global StimObj
 
  if isfield(StimObj, 'Pf')
        save( StimObj.Pf, 'StimObj')
  else
      [file,path] = uiputfile('StimObj.mat','Save StimObj as');
      if file ~= 0
        save([path file], 'StimObj')
      end       
  end



% --------------------------------------------------------------------
function I_saveas_Callback(hObject, eventdata, handles)
% hObject    handle to I_saveas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  global StimObj

  [file,path] = uiputfile('*.mat','Save StimObj as');
  if file == 0
      return
  end
  save([path file], 'StimObj')



% --------------------------------------------------------------------
function I_Read_Callback(hObject, eventdata, handles)
% hObject    handle to I_Read (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  global StimObj

  [FileName,PathName] = uigetfile('*.mat','Select a StimObj Mat-file');
  Pf = fullfile(PathName,FileName);
  if FileName == 0
      return
  end
  load( Pf)
  
    if isfield(StimObj, 'Obj')
        OBJ = StimObj.Obj;
        len = length(OBJ);
        Str_Obj = cell(len, 1);
        for i = 1:len
            Str_Obj(i) = {[num2str(OBJ(i).Id) '-' OBJ(i).Type]};
        end
        set(handles.StimObjLB, 'String', Str_Obj);
        
    end
    
    set(handles.PM_Event, 'Value', 1);
    if isfield(StimObj, 'Stm')
        Stm = StimObj.Stm;
        len = length(Stm);
        Str_Stms = cell(len, 1);
        for i = 1:len
            Str_Stms(i) = {[num2str(Stm(i).Id) '-' Stm(i).Name]};
        end
        set(handles.PM_Event, 'String', Str_Stms);
    end

    StimObj.Pf = Pf;
    guidata(hObject, handles);
    

% --- Executes on selection change in StimObjLB.
function StimObjLB_Callback(hObject, eventdata, handles)
% hObject    handle to StimObjLB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns StimObjLB contents as cell array
%        contents{get(hObject,'Value')} returns selected item from StimObjLB


% --- Executes during object creation, after setting all properties.
function StimObjLB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StimObjLB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global StimObj

if isfield(StimObj, 'Obj')
    OBJ = StimObj.Obj;
    len = length(OBJ);
    Str_Obj = cell(len, 1);
    for i = 1:len
        Str_Obj(i) = {[num2str(OBJ(i).Id) '-' OBJ(i).Type]};
    end
    set(hObject, 'String', Str_Obj);
else
    set(hObject, 'String', {'none'});
end


% --- Executes on button press in Btn_Clr.
function Btn_Clr_Callback(hObject, eventdata, handles)
% hObject    handle to Btn_Clr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cgflip(0,0,0)
cgflip(0,0,0)



% --------------------------------------------------------------------
function M_File_Callback(hObject, eventdata, handles)
% hObject    handle to M_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%//////////////GRAPHIC OBJECT CREATION/////////////////////////////

% --------------------------------------------------------------------
function T_Dot_Callback(hObject, eventdata, handles)
% hObject    handle to T_Dot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
            newObj.Type = 'Dot';
            newObj.Data = cgdot;    
            update_objects(newObj, handles);


% --------------------------------------------------------------------
function T_Box_Callback(hObject, eventdata, handles)
% hObject    handle to T_Box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
            newObj.Type = 'Box';
            newObj.Data = cgbox;    
            update_objects(newObj, handles);

            
% --------------------------------------------------------------------
function T_Bezier_Callback(hObject, eventdata, handles)
% hObject    handle to T_Bezier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

            newObj.Type = 'Bezier';
            newObj.Data = cgbezier;
            update_objects(newObj, handles);



% --------------------------------------------------------------------
function T_Tex_Callback(hObject, eventdata, handles)
% hObject    handle to T_Tex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

            newObj.Type = 'Texture';
            newObj.Data = cgTexture;
            update_objects(newObj, handles);



% --------------------------------------------------------------------
function T_Poly_Callback(hObject, eventdata, handles)
% hObject    handle to T_Poly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

            newObj.Type = 'Polyline';
            newObj.Data = cgPolyline;
            update_objects(newObj, handles);
            
            
% --------------------------------------------------------------------
function T_Bitload_Callback(hObject, eventdata, handles)
% hObject    handle to T_Bitload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [FileName, PathName] = uigetfile('*.bmp', 'Read bitmaps', 'MultiSelect', 'on');
    
    if ischar(FileName)
            newObj.Type = 'Bitmap';
            Bitmap.Filename = [PathName FileName];
            cgloadbmp(1, Bitmap.Filename )           
            spr = cggetdata('SPR', 1);
            Bitmap.cx = 0;
            Bitmap.cy = 0;
            Bitmap.w = spr.Width;
            Bitmap.h = spr.Height;
            Bitmap.Tcol = [];
            Bitmap.isLoaded = false;
            Bitmap.Id = [];
            newObj.Data = Bitmap;
            update_objects(newObj, handles);
      
    elseif  iscell(FileName)
       for i = 1:length(FileName)
            newObj.Type = 'Bitmap';
            Bitmap.Filename = [PathName FileName{i}];
            cgloadbmp(1, Bitmap.Filename )           
            spr = cggetdata('SPR', 1);
            Bitmap.cx = 0;
            Bitmap.cy = 0;
            Bitmap.w = spr.Width;
            Bitmap.h = spr.Height;
            Bitmap.Tcol = [];
            Bitmap.isLoaded = false;
            Bitmap.Id = [];
            newObj.Data = Bitmap;
            update_objects(newObj, handles);
       end
       
    end
    
% --------------------------------------------------------------------
%callback f0r randomsquares pattern
function T_RP_Callback(hObject, ~, handles)
% hObject    handle to T_RP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

            newObj.Type = 'Randompattern';
            newObj.Data = cgRandompattern;
            update_objects(newObj, handles);



% -----------------------------------------------------------------------
function update_objects(Obj, handles)

    global StimObj


        if isfield(StimObj, 'Obj')
            len = length(StimObj.Obj);
        else
            len = 0;
        end
                

        if len == 0
            Obj.Id = 1;
            StimObj.Obj = Obj;
            Str_Obj = {[num2str(Obj.Id) '-' Obj.Type]};
        else
            Str_Obj = get(handles.StimObjLB, 'String');
            Obj.Id = max([ StimObj.Obj(:).Id ]) + 1;
            StimObj.Obj(len+1) = Obj;
            Str_Obj(len+1) = {[num2str(Obj.Id) '-' Obj.Type]};

        end
        
      %  guidata(hObject, handles);
        
        
        set(handles.StimObjLB, 'String', Str_Obj);


% --------------------------------------------------------------------
function Graphic_Object_Callback(hObject, eventdata, handles)
% hObject    handle to Graphic_Object (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function T_Display_Callback(hObject, eventdata, handles)
% hObject    handle to T_Display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global StimObj
    OBJ = StimObj.Obj;
    
    item = get(handles.StimObjLB,'Value');
    switch OBJ(item).Type
        
        case 'Bezier'
            cgbezier(OBJ(item).Data, 'D'); %(D)isplay
        case 'Dot'
            cgdot(OBJ(item).Data, 'D');
        case 'Box'
            cgbox(OBJ(item).Data, 'D');
        case 'Polyline'
            cgPolyline(OBJ(item).Data, 'D');
        case 'Bitmap'
            StimObj.Obj(item).Data = cgbitmap(OBJ(item).Data, 'D', OBJ(item).Id);
            %update bitmap because isloaded is true and Id is added
            %since this is a sprite
        case 'Texture'
            Tex = OBJ(item).Data;
            Id = OBJ(item).Id;
            StimObj.Obj(item).Data = cgTexture(Tex, 'D', Id);
            %also becomes a sprite
        case 'Randompattern'
            RP = OBJ(item).Data;
            %Id = OBJ(item).Id;
            cgRandompattern(RP);
          %  StimObj.Obj(item).Data = RP;
            %this objects changes on each presentation
   end
        
% --------------------------------------------------------------------
function T_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to T_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global StimObj
    OBJ = StimObj.Obj;
    
    set(handles.stimeditor, 'Visible', 'off');
    item = get(handles.StimObjLB,'Value');
    
        if strcmp(OBJ(item).Type, 'Bezier')
            Bez = OBJ(item).Data;
            StimObj.Obj(item).Data = cgbezier(Bez, 'E');

        elseif strcmp(OBJ(item).Type, 'Dot')
            Dot = OBJ(item).Data;
            StimObj.Obj(item).Data = cgdot(Dot, 'E');
        
       elseif strcmp(OBJ(item).Type, 'Box')
            Box = OBJ(item).Data;
            StimObj.Obj(item).Data = cgbox(Box, 'E');
            
       elseif strcmp(OBJ(item).Type, 'Polyline')
            Poly = OBJ(item).Data;
            StimObj.Obj(item).Data = cgPolyline(Poly, 'E');
            
        elseif strcmp(OBJ(item).Type, 'Texture')
            Tex = OBJ(item).Data;
            StimObj.Obj(item).Data = cgTexture(Tex, 'E');
            
        elseif strcmp(OBJ(item).Type, 'Bitmap')
            Bmp = OBJ(item).Data;
            Id = OBJ(item).Id;
            StimObj.Obj(item).Data = cgbitmap(Bmp, 'E', Id);
        end
        
    set(handles.stimeditor, 'Visible', 'on');
    
% --------------------------------------------------------------------
function T_Del_Callback(hObject, eventdata, handles)
% hObject    handle to T_Del_Stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        global StimObj
        numObj = length(StimObj.Obj);
        item = get(handles.StimObjLB,'Value');
        Str_Obj = get(handles.StimObjLB, 'String');
        
            ID = StimObj.Obj(item).Id;
            Inuse = 0;
            if isfield(StimObj, 'Stm')
                Stms = StimObj.Stm;
                lenStm = length(Stms);
                for i = 1:lenStm
                   IdA = [ Stms(i).Event{:} Stms(i).Fix Stms(i).Targ Stms(i).Talt{:} ]; 
                   Inx = find(IdA == ID, 1);
                   if ~isempty(Inx) %this Id is used in one of the stimuli
                       errordlg(['Cannot delete this object, used by stimulus Id ' num2str(Stms(i).Id) ])
                       Inuse = 1;
                       break
                   end
                end
            end
            if Inuse == 0
                StimObj.Obj(item) = [];
                
                if (numObj - 1) == 0
                    Str_Obj = ' ';
                else
                    Str_Obj(item) = [];
                end
                set(handles.StimObjLB, 'String', Str_Obj, 'Value', 1);
            end

% --------------------------------------------------------------------
function T_Copy_Callback(hObject, eventdata, handles)
% hObject    handle to T_Copy_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        global StimObj
        OBJ = StimObj.Obj;
        len = length(OBJ);
        item = get(handles.StimObjLB,'Value');
        Str_Obj = get(handles.StimObjLB, 'String');

        StimObj.Obj(len + 1) = OBJ(item);
        IDs = [OBJ(:).Id ];
        StimObj.Obj(len + 1).Id = max(IDs) + 1;

        newObj = StimObj.Obj(len + 1);
        Str_Obj(len+1) = {[num2str(newObj.Id) '-' newObj.Type]};
        set(handles.StimObjLB, 'String', Str_Obj);


%///////////////////STIMULUS CREATE AND EDIT//////////////////////////////
 
% --- Executes on selection change in PM_EVENT.
function PM_Event_Callback(hObject, eventdata, handles)
% hObject    handle to PM_EVENT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns PM_EVENT contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM_EVENT


%UPDATE STIMULUS PARAMATER PANEL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
global StimObj

    Objs = StimObj.Obj;  %graphic object array
    lenObj = length(Objs);
 %   Str_Obj = cell(1,2);
    Ctrl_Obj = cell(1,2); %objects used to position control windows, (need a center position: cx, cy)
    IDS = [];
    
    Ind = 1;
    for i = 1:lenObj
        if isfield(Objs(i).Data, 'cx') %does this object have a center point
            Ctrl_Obj(Ind) = {[num2str(Objs(i).Id) '-' Objs(i).Type]};
            IDS(Ind) = Objs(i).Id;
            Ind = Ind + 1;
        end
  %      Str_Obj(i) = {[num2str(Objs(i).Id) '-' Objs(i).Type]};
    end
    Ctrl_Obj(Ind) = {'NONE'};
    
    Stmnum = get(hObject,'Value');  %the selected stimulus
    %Str_Stm = get(hObject,'String');
    Stim = StimObj.Stm(Stmnum);
    EVENT = Stim.Event;
    %E_Fixon, E_Stimon, E_Targon,  E_Targoff,  PU_Fix, PU_Correct, LB_Error
    %E = edit t_box
    %PU = popup t_box
    %LB = listbox
    
    
    set(handles.E_Fixon, 'String', num2str( EVENT{1}) )
    set(handles.E_Stimon, 'String', num2str( EVENT{2}) )
    set(handles.E_Targon, 'String', num2str( EVENT{3}) )
    set(handles.E_Targoff, 'String', num2str( EVENT{4}) )
    
     if ~isempty(Stim.Fix)
         Idx = find(IDS == Stim.Fix, 1);
         set(handles.PU_Fix, 'String', Ctrl_Obj, 'value', Idx)
     else
         set(handles.PU_Fix, 'String', Ctrl_Obj, 'value', Ind)
     end
     if ~isempty(Stim.Targ)
         Idx = find(IDS == Stim.Targ, 1);
         set(handles.PU_Correct, 'String', Ctrl_Obj, 'value', Idx )
     else
         set(handles.PU_Correct, 'String', Ctrl_Obj, 'value', Ind)
     end
     
     Ids = Stim.Talt{:};
     Mx = length(Ctrl_Obj) -1;
     if ~isempty(Ids)
         Idx = [];
         for j = 1:length(Ids)
            Idx = [Idx find(IDS == Ids(j),1) ]; %#ok<AGROW>
         end
         
         set(handles.LB_Error, 'String', Ctrl_Obj, 'value', Idx, 'Max', Mx)
     else
         set(handles.LB_Error, 'String', Ctrl_Obj, 'value', Ind, 'Max', Mx)
     end
     handles.IDS = IDS; %save the Ctrl IDS in the handles stucture for updating
    guidata(hObject, handles);
    

% --- Executes during object creation, after setting all properties.
function PM_Event_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PM_EVENT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

%FILL STIMULUS POPUP LIST
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global  StimObj
   if isfield(StimObj, 'Stm')
   
        Stms = StimObj.Stm;
        len = length(Stms);
        if len > 0
            Str_Stms = cell(len, 1);
            for i = 1:len
                Str_Stms(i) = {[num2str(Stms(i).Id) '-' Stms(i).Name]};
            end
            set(hObject, 'String', Str_Stms);
        else
            set(hObject, 'String', {'none'});
        end
   else
       set(hObject, 'String', {'none'});
   end


function Pre_T_Callback(hObject, eventdata, handles)
% hObject    handle to Pre_T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Pre_T as text
%        str2double(get(hObject,'String')) returns contents of Pre_T as a double


% --- Executes during object creation, after setting all properties.
function Pre_T_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Pre_T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in E_Fixon.
function E_Fixon_Callback(hObject, eventdata, handles)
% hObject    handle to E_Fixon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns E_Fixon contents as cell array
%        contents{get(hObject,'Value')} returns selected item from E_Fixon
    global StimObj
     
    Objs = StimObj.Obj;
    Stmnum = get(handles.PM_Event,'Value');
    IdE = str2num(get(hObject,'String'));
    IDs = [ Objs(:).Id ];
    if any(setdiff(IdE, IDs))
        errordlg('Only numbers corresponding to stimulus objects (IDs)')
    else   
        StimObj.Stm(Stmnum).Event(1) = { IdE };
    end

% --- Executes during object creation, after setting all properties.
function E_Fixon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Fixon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function E_Stimon_Callback(hObject, eventdata, handles)
% hObject    handle to E_Stimon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Stimon as text
%        str2double(get(hObject,'String')) returns contents of E_Stimon as a double
    global StimObj
    
    Objs = StimObj.Obj;
    Stmnum = get(handles.PM_Event,'Value');
    IdE = str2num(get(hObject,'String'));
    IDs = [ Objs(:).Id ];
    if any(setdiff(IdE, IDs))
        errordlg('Only numbers corresponding to stimulus objects (IDs)', 'Invalid input!!!')
    else 
        StimObj.Stm(Stmnum).Event(2) = { IdE };
    end

% --- Executes during object creation, after setting all properties.
function E_Stimon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Stimon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Targon_Callback(hObject, eventdata, handles)
% hObject    handle to E_Targon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of E_Targon as text
%        str2double(get(hObject,'String')) returns contents of E_Targon as a double
    global StimObj
       
    Objs = StimObj.Obj;
    Stmnum = get(handles.PM_Event,'Value');
    IdE = str2num(get(hObject,'String'));
    IDs = [ Objs(:).Id ];
    if any(setdiff(IdE, IDs))
        errordlg('Only numbers corresponding to stimulus objects (IDs)')
    else
        StimObj.Stm(Stmnum).Event(3) = { IdE };
    end

% --- Executes during object creation, after setting all properties.
function E_Targon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to E_Targon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function E_Targoff_Callback(hObject, eventdata, handles)
% hObject    handle to e_Targoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_Targoff as text
%        str2double(get(hObject,'String')) returns contents of e_Targoff as a double
    global StimObj
       
    Objs = StimObj.Obj;
    Stmnum = get(handles.PM_Event,'Value');
    IdE = str2num(get(hObject,'String'));
    IDs = [ Objs(:).Id ];
    if any(setdiff(IdE, IDs))
        errordlg('Only numbers corresponding to stimulus objects (IDs)')
    else
        StimObj.Stm(Stmnum).Event(4) = { IdE };
    end
    

% --- Executes during object creation, after setting all properties.
function E_Targoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_Targoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PU_Fix.
function PU_Fix_Callback(hObject, eventdata, handles)
% hObject    handle to PU_Fix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns PU_Fix contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PU_Fix
    global StimObj
       
    Stmnum = get(handles.PM_Event,'Value');
    
    num = get(hObject,'Value');
    if ~(num > length(handles.IDS))
        StimObj.Stm(Stmnum).Fix = handles.IDS(num);
    else
        errordlg('You must select a fixation target')
    end
   
    
    
    
% --- Executes during object creation, after setting all properties.
function PU_Fix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PU_Fix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PU_Correct.
function PU_Correct_Callback(hObject, eventdata, handles)
% hObject    handle to PU_Correct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns PU_Correct contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PU_Correct
    global StimObj
       
    Stmnum = get(handles.PM_Event,'Value');
    
    num = get(hObject,'Value');
    if ~(num > length(handles.IDS))
        StimObj.Stm(Stmnum).Targ = handles.IDS(num);
    else
        errordlg('You must select a correct target')
    end
    

% --- Executes during object creation, after setting all properties.
function PU_Correct_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PU_Correct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in LB_Error.
function LB_Error_Callback(hObject, eventdata, handles)
% hObject    handle to LB_Error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns LB_Error contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LB_Error
    global StimObj
       
    Stmnum = get(handles.PM_Event,'Value');
    
    num = get(hObject,'Value');
    if any(num > length(handles.IDS))
        StimObj.Stm(Stmnum).Talt = {[]};
        
    else
        StimObj.Stm(Stmnum).Talt = { handles.IDS(num) };
    end

% --- Executes during object creation, after setting all properties.
function LB_Error_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LB_Error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --------------------------------------------------------------------
function Stimulus_Object_Callback(hObject, eventdata, handles)
% hObject    handle to Stimulus_Object (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --------------------------------------------------------------------
function T_Display_stim_Callback(hObject, eventdata, handles)
% hObject    handle to T_Display_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global StimObj
    
    Objs = StimObj.Obj;  %graphic object array
   % lenObj = length(Objs);
    Stmnum = get(handles.PM_Event,'Value');
   % Str_Stm = get(handles.PM_Event,'String');
    Stim = StimObj.Stm(Stmnum);
    Str_EVENT = {'Fix', 'Stim', 'Targ', 'Targoff' };
    BGcolor = handles.Backgroundcolor;
    cgflip(BGcolor(1), BGcolor(2), BGcolor(3));

           ObjIds = [ Objs(:).Id ];
            if ~isempty(Stim.Fix)
                FIn = find(ObjIds == Stim.Fix);
                Fix = [Objs(FIn).Data.cx Objs(FIn).Data.cy Objs(FIn).Data.w Objs(FIn).Data.h];
            end
            
            if ~isempty(Stim.Targ)
                TIn = find(ObjIds == Stim.Targ);
                Targ = [Objs(TIn).Data.cx Objs(TIn).Data.cy Objs(TIn).Data.w Objs(TIn).Data.h];
            end
            TA = Stim.Talt{:};
            Talt = [];
            for i = 1:length(TA)
                TIn = find(ObjIds == TA(i));
                Talt = [Talt; Objs(TIn).Data.cx Objs(TIn).Data.cy Objs(TIn).Data.w Objs(TIn).Data.h];
            end
            
            %you should identify bitmaps and textures, and load them in advance
            Ids = unique([ Stim.Event{:}]); %get all object ids in stimulus
            for i = 1:length(Ids)
               Oix = find(ObjIds == Ids(i));  
               if strcmp(Objs(Oix).Type, 'Texture')
                    Objs(Oix).Data = cgTexture(Objs(Oix).Data, 'L', Ids(i)); %load the texture
               elseif strcmp(Objs(Oix).Type, 'Bitmap')
                   Objs(Oix).Data = cgbitmap(Objs(Oix).Data, 'L', Ids(i)); %load the bitmap
               elseif strcmp(Objs(Oix).Type, 'Bezier')
                   Objs(Oix).Data = cgbezier(Objs(Oix).Data, 'S', Ids(i)); %load the bezier
               elseif strcmp(Objs(Oix).Type, 'Randompattern')
                   Objs(Oix).Data = cgRandompattern(Objs(Oix).Data, 'sprite', Ids(i)); %load the Randompattern
               end                 
            end
            
            for i = 1:4
                STM = Stim.Event{i};
                if ~isempty(STM)
                    cgplotstim(STM, Objs); %cell array -> (Id) array
                    
                    cgpenwid(1)
                    cgpencol(1, 1, 1)
                    cgfont('Arial',20)
                    cgtext( Str_EVENT{i}, 200, 0)
                    
                    if ~isempty(Stim.Fix)
                        cgellipse(Fix(1), Fix(2), Fix(3), Fix(4), [1 1 1])
                        cgtext( 'Fix', Fix(1) + 100, Fix(2))
                    end
                    if ~isempty(Stim.Targ)
                        cgellipse(Targ(1), Targ(2), Targ(3), Targ(4), [1 1 1])
                        cgtext( 'C_T', Targ(1), Targ(2) + 50)
                    end
                    for k = 1:length(TA)
                        cgellipse(Talt(k,1), Talt(k,2), Talt(k,3), Talt(k,4), [1 1 1])
                        cgtext( 'I_T', Talt(k,1), Talt(k,2) + 50)
                    end
                    
                    cgflip(BGcolor(1), BGcolor(2), BGcolor(3));

                    pause( 2)
                end
            end




% --------------------------------------------------------------------
function T_Del_Stim_Callback(hObject, eventdata, handles)
% hObject    handle to T_Del_Stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%CONTEXT MENU CALLBACK TO DELETE A STIMULUS
    global StimObj
    
                Stmnum = get(handles.PM_Event,'Value');
                Str_Stm = get(handles.PM_Event,'String');
                StimObj.Stm(Stmnum) = [];
                
                Str_Stm(Stmnum) = [];
                set(handles.PM_Event, 'String', Str_Stm, 'Value', 1);



% --------------------------------------------------------------------
function T_Copy_stim_Callback(hObject, eventdata, handles)
% hObject    handle to T_Copy_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%CONTEXT MENU CALLBACK TO COPY A STIMULUS
    global StimObj
                
        Stmnum = get(handles.PM_Event,'Value');
        Str_Stm = get(handles.PM_Event,'String');
        Stim = StimObj.Stm(Stmnum);
        IDs = [ StimObj.Stm(:).Id ];
        len = length(IDs);
        Stim.Id = max(IDs) + 1;
        StimObj.Stm(len+1) = Stim;


         Str_Stm(len+1) = {[num2str(Stim.Id) '-' Stim.Name]};
         set(handles.PM_Event, 'String', Str_Stm, 'Value', 1);

                 
% --------------------------------------------------------------------
function Create_stimulus( hObject, eventdata, hedit, handles )
    global StimObj
            if isfield(StimObj, 'Stm')
                if ~isempty(StimObj.Stm)
                    IDs = [ StimObj.Stm(:).Id ];
                    len = length(IDs);
                else 
                    IDs = 0;
                    len = 0;
                end
            else
                IDs = 0;
                len = 0;
            end
            
            Str_stim = get( hedit, 'String');
            newStim.Name = Str_stim;
            newStim.Id = max(IDs) + 1;
            newStim.Fix = [];
            newStim.Targ = [];
            newStim.Talt = {[]};
            newStim.Event = cell(5,1);
            
            StimObj.Stm(len+1) = newStim;

            Str_Stm = get(handles.PM_Event, 'String');
            Str_Stm(len+1) = {[num2str(newStim.Id) '-' newStim.Name]};
            set(handles.PM_Event, 'String', Str_Stm, 'Value', 1);
            delete(gcf)

% --------------------------------------------------------------------
function T_New_Callback(hObject, eventdata, handles)
% hObject    handle to T_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%CONTEXT MENU CALLBACK TO CREATE A NEW STIMULUS
    POS = get(handles.figure1, 'Position');
    HF = figure('Position', [(POS(1)+40) 700 200 60], 'MenuBar', 'none', 'NumberTitle', 'off', 'name', 'Stim name');
    hedit = uicontrol(HF, 'style', 'edit', 'Position', [10 35 180 20]);
    
    uicontrol(HF, 'style', 'pushbutton', 'string', 'Ok', 'Position', [80 5 50 20], ...
                    'Callback', { @Create_stimulus, hedit, handles } );
    uicontrol(HF, 'style', 'pushbutton', 'string', 'Cancel', 'Position', [130 5 50 20],...
                   'Callback', { @delete, gcf } );
    
 
% --------------------------------------------------------------------
function T_BGColor_Callback(hObject, eventdata, handles)
% hObject    handle to T_BGColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 BGcolor = handles.Backgroundcolor;
 answ = inputdlg({'R', 'G', 'B'}, 'Enter RGB 0-1' , 1, {num2str(BGcolor(1)), num2str(BGcolor(2)), num2str(BGcolor(3)) } );
 
 if ~isempty(answ)
    handles.Backgroundcolor = [str2double(answ{1}) str2double(answ{2}) str2double(answ{3})];
    guidata(hObject, handles);
 end
 
 
 
