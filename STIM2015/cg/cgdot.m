function Dot = cgdot( varargin )
%function Dot = cgdot( varargin )
%Dot.cx : x position
%   .cy : y postion
%   .w  : width
%   .h  : height
%   .color : [ 1 1 1]
%   .fill  : 'f' or []

if nargin > 0
    Dot = varargin{1};
    if ~isstruct(Dot)
        disp('Invalid cgdot USAGE:')
        help cgdot
        return
    end
    Mode = 0;  %adds to existing dots
else
    Dot = [];  %new 
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

if Mode == 'R'
    
    rot = varargin{3};
    cx = Dot.cx;
    cy = Dot.cy;
    
    rot = rot /180 * pi;
    R = sqrt(cx^2 + cy^2);
    Ango =  atan2(cy, cx);
    cx = cos(Ango + rot) * R;
    cy = sin(Ango + rot) * R;
    
    Dot.cx = cx;
    Dot.cy = cy;   
end

if ~isempty(Dot)% if Mode ~= 'D'  %clear screen
    len = length(Dot);
    if Mode == 'P'
        for i = 1:len
            cgellipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, Dot(i).color, Dot(i).fill)
        end
        return
    else
        for i = 1:len
            cgellipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, Dot(i).color, Dot(i).fill)
            cgflip
            cgellipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, Dot(i).color, Dot(i).fill)
        end
    end
end

if Mode == 'D' || Mode == 'R' %just display graphics
    return
end

global Par

cgkeymap(); %clear keymap
ESC = 0;
gsd = cggetdata('gsd'); 
while ~ESC && (Mode == 0 || Mode == 'E')
    cgfont('Verdana',20)
    cgpencol(1,1,1)
    cgtext('ESC to return!!!!!', 200-gsd.PixOffsetX, 20-gsd.PixOffsetY)
    bd = 0;
    if Mode == 0 %new and add mode
        [x,y, bd] = cgmouse;
        while ( bd ~= 1 && ~ESC ) %wait for button press or escape 
            pause(0.01)
            [kd, kp] = cgkeymap();
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
                cgellipse(cx,cy,2*R,2*R, RGB', 'f')    
                cgflip()
                cgellipse(cx,cy,2*R,2*R, RGB', 'f')

                if isempty(Dot)
                    Dot = struct('cx', cx, 'cy', cy, ...
                        'w', 2*R, 'h', 2*R, 'color', RGB', 'fill' , 'f');
                else
                   len = length(Dot);
                   Dot(len+1) = struct('cx', cx, 'cy', cy, ...
                        'w', 2*R, 'h', 2*R, 'color', RGB', 'fill' , 'f');
                end
            end
            ESC = 1;  %escape otherwise more dots are added to this Obj
        end
     elseif  Mode == 'E'
         
         gsd = cggetdata('gsd');
         if isfield(Par, 'PixPerDeg')
            PPD = Par.PixPerDeg;    
         else   
             PPD = 25;
         end
         
         prompt = {'Position x in degrees', ...
                   'Position x in degrees', ...
                   'Diameter in visual degrees', ...
                   'Red Green and Blue color values <1.0 as < 0.1 0.1 0.1 >', ...
                   'Apply rotation'};
               
         dlg_title =  'Edit parameters for dot object';
         num_lines = 1;
         def = { num2str(Dot.cx / PPD),  num2str(Dot.cy / PPD) , num2str(Dot.w / PPD) , num2str(Dot.color) , '0'};        
         StrDot = inputdlg(prompt, dlg_title, num_lines, def);
         
         if ~isempty( StrDot) 
             cx = round(str2double(StrDot{1}) * PPD);
             cy = round(str2double(StrDot{2}) * PPD);
             width = round(str2double(StrDot{3}) * PPD);
             
             color = ( str2num( StrDot{4}) );  
             
             rot = str2double(StrDot{5});
             if rot ~= 0
                 rot = rot /180 * pi;
                 R = sqrt(cx^2 + cy^2);
                 Ango =  atan2(cy, cx);
                 cx = cos(Ango + rot) * R;
                 cy = sin(Ango + rot) * R;
             end
         
             if isnan(cx) || isnan(cy) || isnan(width) || length(color) < 3
                 %dont return values, show menu again!!!
             else
                 Dot.cx = cx;
                 Dot.cy = cy;
                 Dot.w = width;
                 Dot.h = Dot.w;
                 Dot.color = color;
                 ESC = 1;
             end
             
         else  %%cancel must have been pressed
             ESC = 1;
         end
%          cgpencol(1, 1, 1)
%          cgFont('Verdana', 24)
%          cgtext('Edit Dot', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
%          cgflip
%          cgtext('Edit Dot', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
         
         
%         [x,y, bd] = cgmouse;
%         while ( bd ~= 1 && ~ESC ) %wait for button press or escape or close curve (C key)
%             pause(0.01)
%             [kd, kp] = cgKeyMap();
%             ESC = kp(1);
%             
%             [cx,cy, bd] = cgmouse;  
%         end 
%         if ~ESC
%             while bd == 1 %wait for button release to get radius
%                 pause(0.01)
%                 [rx,ry, bd] = cgmouse;       
%             end 
%             len = length(Dot);

% Cartesian equation: 
% x2/a2 + y2/b2 = 1 
% or parametrically: 
% x = a cos(t), y = b sin(t) 


%             for i = 1:len
%                 if  (Dot(i).cx - cx)^2/(0.5* Dot(i).w)^2 + (Dot(i).cy - cy)^2/(0.5* Dot(i).h)^2 < 1
% 
%                     cgEllipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, [0 0 0], Dot(i).fill)
%                     cgflip
%                     cgEllipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, [0 0 0], Dot(i).fill)
% 
%                     Dot(i).cx = rx;
%                     Dot(i).cy = ry;
%                     cgEllipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, Dot(i).color, Dot(i).fill)
%                     cgflip
%                     cgEllipse(Dot(i).cx, Dot(i).cy, Dot(i).w, Dot(i).h, Dot(i).color, Dot(i).fill)
%                     break;
%                 end
%             end

%        
%             prompt = {'Position cx cy:', 'Width and Height', 'Color:'};
%             dlg_title = 'Edit position and color values 0.0-1.0';
%             num_lines = 1;
%             def = {[num2str(Dot.cx) ' ' num2str(Dot.cy)] , [num2str(Dot.w) ' ' num2str(Dot.h)], num2str(Dot.color) };
%             StrOut = inputdlg(prompt,dlg_title,num_lines,def);
%             P = str2num(StrOut{1});
%             Dot.cx = P(1);
%             Dot.cy = P(2);
%             P = str2num(StrOut{2});
%             Dot.w = P(1);
%             Dot.h = P(2);
%             Dot.color = str2num(StrOut{3});
%             ESC = 1;
%           
%        else
%                 cgpencol(0, 0, 0)
%                 cgtext('Edit Dot', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
%                 cgflip
%                 cgtext('Edit Dot', 40 -gsd.PixOffsetX, 24 - gsd.PixOffsetY )
%        end
    end
     
end

cgflip(0,0,0)
cgflip(0,0,0)
