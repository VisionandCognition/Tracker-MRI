function Box = cgbox( varargin )
%function Box = cgbox( varargin )


if nargin > 0
    Box = varargin{1};
    if ~isstruct(Box)
        disp('Invalid cgbox USAGE:')
        help cgbox
        return
    end
    Mode = 0;  %adds to existing dots
else
    Box = [];  %new 
    Mode = 0;
end

if nargin > 1 %must be 2 or 3 to go in edit mode
    Mode = varargin{2};
end


A = cgflip('v');
if A == -2
    disp('Open a Cogent window before using this function!!!');
    
    return
end
if ~isempty(Box)% if Mode ~= 'D'  %clear screen
    len = length(Box);
    if Mode == 'P'
        for i = 1:len
            cgpencol(Box(i).color(1), Box(i).color(2), Box(i).color(3))
            cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
        end
        return
    else
        for i = 1:len
            cgpencol(Box(i).color(1), Box(i).color(2), Box(i).color(3))
            cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
            cgflip
            cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
        end
    end
end
if Mode == 'D' %just display graphics
    return
end



cgkeymap(); %clear keymap
K_CTRL = 0;
ESC = 0;

gsd = cggetdata('gsd'); 
while ~ESC && (Mode == 0 || Mode == 'E')
    cgfont('Verdana',20)
    cgpencol(1,1,1)
    cgtext('ESC to return!!!!!', 200-gsd.PixOffsetX, 20-gsd.PixOffsetY)

    if Mode == 0 %new and add mode
        [~,~, bd] = cgmouse;
        while ( bd ~= 1 && ~ESC ) %wait for button press or escape 
            pause(0.01)
            [~, kp] = cgkeymap();
            ESC = kp(1);            
            [cx,cy, bd] = cgmouse;  
        end
        if ~ESC
            while bd == 1 %wait for button release to get radius
                pause(0.01)
                [rx,ry, bd] = cgmouse;       
            end
            R = sqrt((cx - rx)^2 + (cy - ry)^2);

            prompt = {'Red:','Green:', 'Blue:'};
            dlg_title = 'Enter color values 0.0-1.0';
            num_lines = 1;
            def = {'1','1', '1'};
            StrRGB = inputdlg(prompt,dlg_title,num_lines,def);
            if ~isempty( StrRGB ) 
                RGB = sscanf([StrRGB{1} ' ' StrRGB{2} ' ' StrRGB{3}], '%f', 3);
                cgpencol(RGB(1), RGB(2), RGB(3))
                cgrect(cx,cy,2*R,2*R)    
                cgflip()
                cgrect(cx,cy,2*R,2*R)

                if isempty(Box)
                    Box = struct('cx', cx, 'cy', cy, ...
                        'w', 2*R, 'h', 2*R, 'color', RGB);
                else
                   len = length(Box);
                   Box(len+1) = struct('cx', cx, 'cy', cy, ...
                        'w', 2*R, 'h', 2*R, 'color', RGB');
                end
            end
        end
     elseif  Mode == 'E'
         
         gsd = cggetdata('gsd');
         cgpencol(1, 1, 1)
         cgfont('Verdana', 24)
         cgtext('Edit Box', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
         cgflip
         cgtext('Edit Box', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
         
        [~,~, bd] = cgmouse;
        while ( bd ~= 1 && ~ESC ) %wait for button press or escape
            pause(0.01)
            [~, kp] = cgkeymap();
            KP = find(kp, 1, 'first');
            
            if ~isempty(KP)
                switch KP
                    case 1
                        ESC = 1;
%                     case 83
%                         K_DEL = 1;
%                     case 42
%                         K_SHIFT = 1; %has the shift key been pressed
                    case 29
                        K_CTRL = 1;%Has left CRTL key been pressed,
                        %value editing
                end
            end
            
            
            [cx,cy, bd] = cgmouse;  
        end 
        if ~ESC
            while bd == 1 %wait for button release to get radius
                pause(0.01)
                [rx,ry, bd] = cgmouse;       
            end 
            len = length(Box);

% Cartesian equation: 
% x2/a2 + y2/b2 = 1 
% or parametrically: 
% x = a cos(t), y = b sin(t) 


            for i = 1:len
                if  (Box(i).cx - cx)^2/(0.5* Box(i).w)^2 + (Box(i).cy - cy)^2/(0.5* Box(i).h)^2 < 1                   
                    if ~K_CTRL
                        cgpencol(0, 0, 0)
                        cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                        cgflip
                        cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)

                        cgpencol(Box(i).color(1), Box(i).color(2), Box(i).color(3))
                        Box(i).cx = rx;
                        Box(i).cy = ry;
                        cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                        cgflip
                        cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                    else
                        FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Edit', 'Position', [100 300 200 150]); 

                        uc = uicontrol('Style','Toggle','String','Cancel',...
                                        'pos',[80 10 50 20],'parent',FG);
                        u0 = uicontrol('Style','Pushbutton','String','OK',...
                                        'pos',[25 10 50 20],'parent',FG);


                        u2 = uicontrol('Style','Pushbutton','String','Change values',...
                                        'pos',[25 35 150 20],'parent',FG);
                        u3 = uicontrol('Style','Pushbutton','String','Change color',...
                                        'pos',[25 60 150 20],'parent',FG);
                                    
                        Hdl = guihandles(FG);
                        Hdl.Box = Box(i);
                        guidata(FG, Hdl)            
                                    
                        set(u0, 'Callback', {@CloseMenu, FG});
                        set(uc, 'Callback', {@CloseMenu, FG});
                        set(u2, 'Callback', {@editvalues, FG});
                        set(u3, 'Callback', {@Changecolor, FG});
                                             
                        uiwait(FG)
                        if ishandle(FG)
                            Hdl = guidata(FG);
                            if Hdl.Res
                                cgpencol(0, 0, 0)
                                cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                                cgflip
                                cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                                
                                Box(i) = Hdl.Box;
                                
                                cgpencol(Box(i).color(1), Box(i).color(2), Box(i).color(3))
                                cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                                cgflip
                                cgrect(Box(i).cx, Box(i).cy, Box(i).w, Box(i).h)
                                
                            end
                            close(FG)
                        end 
                        
                        K_CTRL = 0;
                    end
                    break;
                    
                end
            end
         
        else
                cgpencol(0, 0, 0)
                cgtext('Edit Box', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
                cgflip
                cgtext('Edit Box', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
        end
    end
     
end

cgflip(0,0,0)
cgflip(0,0,0)

function CloseMenu( hObject, eventdata, FH)
      
      Handles = guidata(FH);
      Handles.Res = 0;
      STR = get(hObject, 'String');
      if strcmp(STR, 'OK')
          Handles.Res = 1;          
      end
      guidata(FH, Handles)
      uiresume(FH)

function editvalues( hObject, eventdata, FH)

    Hndl = guidata(FH);
    Box = Hndl.Box;
    
    prompt = {'CenterX', 'CenterY', 'Width', 'Height'};
    Def = { num2str(Box.cx), num2str(Box.cy), num2str(Box.w), num2str(Box.h)};
    answ = inputdlg(prompt, 'edit values' , 1, Def);
    
    cx = str2double(answ{1});
    if abs(cx)< 1000, Box.cx = cx; end 
    cy = str2double(answ{2});
    if abs(cy)< 1000, Box.cy = cy; end 
    w = str2double(answ{3});
    if abs(w)< 1000, Box.w = w; end 
    h = str2double(answ{4});
    if abs(h)< 1000, Box.h = h; end 
    
    Hndl.Box = Box;
    guidata(FH, Hndl)
    
    
function Changecolor( hObject, eventdata, FH)

         Hndl = guidata(FH);
         Box = Hndl.Box; 
         
         c = uisetcolor(Box.color);            
         Box.color = c;
         Hndl.Box = Box;
        guidata(FH, Hndl)
   
        
    