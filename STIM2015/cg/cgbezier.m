function Bez = cgbezier( varargin )
% Bez = cgbezier( ) makes a new Bezier curve
% Bez = cgbezier( Bez ) adds to existing bezier
%                       exit function with ESC or C (to close the curve)
%       cgbezier( Bez , 'B') %blit the bezier as a sprite
%       cgbezier(Bez, 'S', Id)  %make a sprite
% Bez = cgbezier( Bez , 'P') %just plot on back buffer
% Bez = cgbezier( Bez , 'D') %just display the Bezier, no further
%                           interaction
%       To edit an existing bezier curve
% Bez = cgbezier( Bez, 'E' ) 
% Bez = cgbezier(Bez, 'R', Angle ) %rotate bezier by Angle degrees

%In edit mode:
%       L mouse Click, hold and drag control points to other locations
%       L mouse Click and let go; to delete a control point and segment of the curve
%       L SHIFT key press then mouse Click, hold and drag to drag entire curve to a new position
%       L CTRL key press then Click and let go to enter values with menu
%      

%16-01-2007
%updated 11-06-2008
%updated 4-11-2011 ; To accomodate rotation
%updated 14-10-2012 ; To accomodate stimulus rotation
%updated 13-2-2013 ; You can now add points in the Bez.P and redraw the stimulus 
%        25-2-2013  ; give your bezier a nice color

%C van der Togt
%Vision and Cognition

if nargin > 0
    Bez = varargin{1};

    Mode = 0;  %adds to existing curve
else
    Bez = struct;  %new curve
%    Bez.Rotate = @rot;
    Mode = 0;
end

if nargin > 1 %other mode
    Mode = varargin{2};
end


% A = cgflip('v');
% if A == -2
%     disp('Open a Cogent window before using this function!!!');
%     
%     return
% end


if ~isfield(Bez, 'isLoaded')
    Bez.isLoaded = false;
end
    
if Mode == 'B' && Bez.isLoaded %blit sprite with this bezier
    cgdrawsprite(Bez.Id,Bez.S.x,Bez.S.y)
    return
end

cgpenwid(1) %default pen width for beziers
if ~isstruct(Bez)
        disp('Invalid bezier USAGE:')
        help cgbezier
        return
end
%if a Bezier already exists, display it
if ( isfield(Bez, 'L') && ~isempty(Bez.L) )
    if Mode == 'P'  %just plot the Bezier
       BZ = vertcat(Bez.L{:});
       LEN = length(BZ);  
       cgpencol(Bez.Col(1),Bez.Col(2),Bez.Col(3))  
       cgpenwid(Bez.Wid)
       cgdraw(BZ(1:LEN-1,1), BZ(1:LEN-1,2), BZ(2:LEN,1), BZ(2:LEN,2) );

       return
 
    elseif Mode == 'S'  %makes a sprite from the bezier, you must provide an Id in the third argument when cgbezier is called
       
        Id = varargin{3};
       BZ = vertcat(Bez.L{:});
       LEN = length(BZ);
       MM = floor(min(BZ))-1;
       MX = ceil(max(BZ))+1;
       Wd = (MX(1) - MM(1)+1);
       Ht = (MX(2) - MM(2)+1);
       Sx = round(Wd/2 - MX(1));
       Sy = round(Ht/2 - MX(2));
       Bez.S.x = -Sx;
       Bez.S.y = -Sy;
       Bez.Id = Id;
       cgmakesprite(Id, Wd, Ht, 0, 0, 0) %setdimensions and color to black
       cgsetsprite(Id)
       cgpencol(Bez.Col(1),Bez.Col(2),Bez.Col(3))  
       cgpenwid(Bez.Wid)
       cgdraw(BZ(1:LEN-1,1)+Sx, BZ(1:LEN-1,2)+Sy, BZ(2:LEN,1)+Sx, BZ(2:LEN,2)+Sy );
       cgtrncol(Id,'n') %set transparancy to black
       cgsetsprite(0)
       Bez.isLoaded = true;
       
       return
       
    else
       for j = 1:2

           cgpenwid(Bez.Wid)
           cgpencol(Bez.Col(1),Bez.Col(2),Bez.Col(3)) 
           if length(Bez.L) ~= (length(Bez.P)-1)
               len = length(Bez.P);
               for i = 1:len-1
                   P = Bez.P(i:i+1);
                   Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                       (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                       (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);
                   Bez.L(i) = { Line };
                   cgpencol(Bez.Col(1),Bez.Col(2),Bez.Col(3)) 
                   cgdraw(Line(:,1), Line(:,2));
                   cgflip
                   cgdraw(Line(:,1), Line(:,2));
               end
               
           else 
               for i = 1:length(Bez.L)
                   LEN = length(Bez.L{i});
                   cgdraw(Bez.L{i}(1:LEN-1,1), Bez.L{i}(1:LEN-1,2), Bez.L{i}(2:LEN,1), Bez.L{i}(2:LEN,2) );
               end
           end
           
           if Mode == 'E' 
               cgpencol(0,0.7,1)
               cgpenwid(1)
               for i = 1:length(Bez.P)
                    cgellipse(Bez.P(i).x, Bez.P(i).y, 4,4)
               end
               cgpencol(0,1,0)
               for i = 1:length(Bez.P)
                    cgellipse(Bez.P(i).u, Bez.P(i).v, 4,4)
               end
           end
           cgflip
       end
    end
end
if Mode == 'D'  %just display the Bezier
    return
end


if Mode == 'E'  &&  ( ~(isfield(Bez, 'L')) || isempty(Bez.L) ) 
    disp('Cannot edit empty bezier!!!');
    return  
end

global CLOSED
ESC = 0;
CLOSED = false;

if Mode == 'R'  &&  ( (isfield(Bez, 'L')) || ~isempty(Bez.L) )
        A = varargin{3};
        OldBez = Bez;
        len = length(Bez.P);
        Angn = A/180 * pi;
        
        for j = 1:len
            oldx = Bez.P(j).x;
            oldy = Bez.P(j).y;
            Ang = atan2(oldy, oldx); %old angle
            Rp = sqrt(oldx^2 + oldy^2); %radius of point
            Bez.P(j).x = cos(Angn + Ang)*Rp;
            Bez.P(j).y = sin(Angn + Ang)*Rp;

            oldu = Bez.P(j).u;
            oldv = Bez.P(j).v;                  
            Ang = atan2(oldv, oldu); %old angle
            Rp = sqrt(oldu^2 + oldv^2); %radius of point
            Bez.P(j).u = cos(Angn + Ang)*Rp;
            Bez.P(j).v = sin(Angn + Ang)*Rp;
        end

        Bez = UpdateLines( 0, Bez, OldBez);
        
    
end


%loop
cgkeymap(); %clear keymap
K_SHIFT = 0;
K_CTRL = 0;
K_DEL = 0;
K_ROT = 0;
Bez.P2POS = 0; %Linepoint selected
Bez.P2VEC = 0;  %vec or position
while ~ESC && (Mode == 0 || Mode == 'E')
    if Mode == 0 %new and add mode
        Bez.Wid = 1; %initial width of bezier line
        Bez.Col = [1 1 1];
        [x,y, bd] = cgmouse;
        while ( bd ~= 1 && ~ESC && ~CLOSED ) %wait for button press or escape or close curve (C key)
            pause(0.01)
            [~, kp] = cgkeymap();
            ESC = kp(1);
            CLOSED = kp(46);
            [x,y, bd] = cgmouse;  
        end
        if ~ESC && ~CLOSED %if not closed or escaped add a new point
            cgpencol(0,0.7,1)
            cgellipse(x,y,4,4)
            cgflip
            cgellipse(x,y,4,4)
            while bd == 1 %wait for button release to get the position of the direction vector
                pause(0.01)
                [u,v, bd] = cgmouse;  
            end
            cgpencol(0,1,0)
            cgellipse(u,v,4,4)
            cgflip
            cgellipse(u,v,4,4)

            p = [];  %save the points for position and direction vector
            p.x = x;
            p.y = y;
            p.u = u;
            p.v = v;

            if isfield(Bez, 'P') 
                len = length(Bez.P);
            else 
                len = 0;
            end
            Bez.P(len+1) = p;

            if len >= 1
              P = Bez.P(len:len+1);
              Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                              (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                              (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);
              Bez.L(len) = { Line };
              cgpencol(1,1,1) 
              cgdraw(Line(:,1), Line(:,2));
              cgflip
              cgdraw(Line(:,1), Line(:,2));
            end
            
        elseif CLOSED == 1 %close the bezier
            p = Bez.P(1); %copy last Point to end of array
            len = length(Bez.P);
            Bez.P(len+1) = p;
            P = Bez.P(len:len+1);
            Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                              (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                              (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);
            Bez.L(len) = { Line };
            cgpencol(1,1,1) 
            cgdraw(Line(:,1), Line(:,2));
            cgflip
            cgdraw(Line(:,1), Line(:,2));
            
           ESC = 1; %leave the loop, w've closed the bezier anyway 
             
        end %ESC 
        
    elseif Mode == 'E'  %mouse or menu edit mode
        
        len = length(Bez.P);
        if (Bez.P(1).x == Bez.P(len).x && Bez.P(1).y == Bez.P(len).y)
               CLOSED = true; %this line is closed
        end 
        SEL = 0;

        [x,y, bd] = cgmouse;
        while ( bd ~= 1 && ~ESC && ~K_DEL && ~K_CTRL) %wait for button press or escape
            pause(0.01)
            [~, kp] = cgkeymap();
            KP = find(kp, 1, 'first');
            
            if ~isempty(KP)
                switch KP
                    case 1
                        ESC = 1;
                    case 83
                        K_DEL = 1;
                    case 42
                        K_SHIFT = 1; %has the shift key been pressed
                        %Shift whole bezier
                    case 29
                        K_CTRL = 1;%Has left CRTL key been pressed,
                        %value editing
                    case 19
                        K_ROT = 1;  %rotation
                end
            end
            pause(0.05)
            [x,y, bd] = cgmouse;  
        end
        if ~ESC %if not escaped evaluate whether returned point
                %corresponds with the location of one of the bezier points
            if bd == 1
                len = length(Bez.P);
                cgpenwid(1)
                for i = 1:len
                    dx2 = (x-Bez.P(i).x)^2;
                    dy2 = (y-Bez.P(i).y)^2;
                    if sqrt(dx2 + dy2) < 10
                        cgpencol(1,0,1)
                        cgellipse(Bez.P(i).x, Bez.P(i).y,4,4)
                        cgflip
                        cgellipse(Bez.P(i).x, Bez.P(i).y,4,4)
                        SEL = 1; %a point is selected
                        break               
                    end
                    du2 = (x-Bez.P(i).u)^2;
                    dv2 = (y-Bez.P(i).v)^2;
                    if sqrt(du2 + dv2) < 10
                        cgpencol(1,0,1)
                        cgellipse(Bez.P(i).u, Bez.P(i).v,4,4)
                        cgflip
                        cgellipse(Bez.P(i).u, Bez.P(i).v,4,4)
                        SEL = 2; %a direction vector point is selected
                        break               
                    end
                end
               Bez.P2POS = i; %Selected point
               Bez.P2VEC = SEL;
            end
            
            if K_CTRL
                Bez = Valedit(Bez);
                K_CTRL = 0;

            elseif K_DEL
                Bez = DeletePoint(Bez);
                K_DEL = 0;
            elseif K_SHIFT
                Bez = Mouseedit(x, y, i, SEL, Bez, 1 );
                K_SHIFT = 0;
            elseif K_ROT
                Bez = Mouseedit(x, y, i, SEL, Bez, 2 );
                K_ROT = 0;
            else
                Bez = Mouseedit(x, y, i, SEL, Bez, 0 );
               
            end
            
        end %ESC
        
    end %Mode 
end
    
%end of main function Bezier    

 function Bez = Valedit(Bez)
     global Par
     if isfield(Par, 'PixPerDeg')
          PPD = Par.PixPerDeg;    
     else   
          PPD = 25;
     end
     if Bez.P2POS > 0  && Bez.P2VEC > 0 %a point must have been selected
         Pnt = Bez.P2POS; %point
         SEL = Bez.P2VEC; %postion or vector
     
         bd = 1;

         while bd == 1 %wait for button release
               pause(0.01)
               [~,~, bd] = cgmouse; 
         end 


         if SEL == 1 %line point


            FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Edit', 'Position', [100 300 200 150]); 

            uc = uicontrol('Style','Toggle','String','Cancel',...
                'pos',[120 10 50 20],'parent',FG);
            u0 = uicontrol('Style','Pushbutton','String','OK',...
                'pos',[65 10 50 20],'parent',FG);

            u1 = uicontrol('Style','Pushbutton','String','Delete',...
                'pos',[10 35 50 20],'parent',FG);
            u2 = uicontrol('Style','Pushbutton','String','Add',...
                'pos',[65 35 50 20],'parent',FG);
            u3 = uicontrol('Style','Pushbutton','String','Shift',...
                'pos',[120 35 50 20],'parent',FG);


            u4 = uicontrol('Style','Pushbutton','String','FlipLR',...
                'pos',[10 60 50 20],'parent',FG);
            u5 = uicontrol('Style','Pushbutton','String','FlipUD',...
                'pos',[65 60 50 20],'parent',FG);
            u6 = uicontrol('Style','Pushbutton','String','Rotate',...
                'pos',[120 60 50 20],'parent',FG);

            uicontrol('Style','Text','String','Line thickness(px)',...
                'pos',[10 85 110 17],'parent',FG, 'FontSize', 10);
            u7 = uicontrol('Style','Edit','String', num2str(Bez.Wid),...
                'pos',[125 85 30 20],'parent',FG);

            u8 = uicontrol('Style','Pushbutton', 'String', 'Change Color(R G B)',...
                'pos',[10 110 140 20],'parent',FG);



            Hdl = guihandles(FG);
            Hdl.Bez = Bez;
            Hdl.Pnt = Pnt;
            Hdl.PPD = PPD;
            Hdl.Res = 0;
            Hdl.FG = FG;
            guidata(FG, Hdl)

            set(u1, 'Callback', {@deletepos, FG});
            set(u2, 'Callback', {@addpoint, FG});
            set(u3, 'Callback', {@ShiftInputMenu, FG});
            set(u4, 'Callback', {@fliplr, FG});
            set(u5, 'Callback', {@flipud, FG});
            set(u6, 'Callback', {@rotate, FG});
            
            set(u7, 'Callback', {@linewide, FG});
            set(u8, 'Callback', {@linecol, FG});
            set(u0, 'Callback', {@CloseMenu, FG});
            set(uc, 'Callback', {@CloseMenu, FG});


            uiwait(FG)
            if ishandle(FG)
                Hdl = guidata(FG);
                if Hdl.Res
                    Bez = Hdl.Bez;
                end
     %       Res = get(h, 'SelectedObject');
                close(FG)
            end 


         elseif SEL == 2 %direction vector

            P.x = Bez.P(Pnt).x;
            P.y = Bez.P(Pnt).y;
            strx = num2str(Bez.P(Pnt).u);
            stry = num2str(Bez.P(Pnt).v);
            theta = atan2(Bez.P(Pnt).v - Bez.P(Pnt).y, Bez.P(Pnt).u - Bez.P(Pnt).x ) / pi * 180;
            stro = num2str(theta, '%5.1f');
                H = zeros(3,1);
                FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Shift', ...
                    'Position', [100 300 220 180], 'Resize', 'off', 'WindowStyle', 'modal');
                h = uipanel('Position',[0 0 1 1], 'parent', FG);
                uicontrol('Style','Toggle','String','Cancel',...
                      'pos',[150 10 50 20],'parent',h, 'Callback', {@ShiftCall, FG});
                uicontrol('Style','Toggle','String','OK',...
                     'pos',[150 35 50 20],'parent',h, 'Callback', {@ShiftCall, FG});

                uicontrol('Style','Text','String','Vertical position in pixels',...
                      'pos',[10 60 145 20],'parent',h, 'HorizontalAlignment', 'Left');
                H(3) = uicontrol('Style','Edit','String', stry,...
                      'pos',[160 60 40 20],'parent',h);

                uicontrol('Style','Text','String','Horizontal position in pixels',...
                      'pos',[10 85 145 20],'parent',h, 'HorizontalAlignment', 'Left');
                H(2) = uicontrol('Style','Edit','String', strx,...
                      'pos',[160 85 40 20],'parent',h);

                uicontrol('Style','Text','String','Orientation in degrees',...
                      'pos',[10 110 145 20],'parent',h, 'HorizontalAlignment', 'Left');
                H(1) = uicontrol('Style','Edit','String', stro,...
                      'pos',[160 110 40 20],'parent',h);

    %             uicontrol('Style','Text','String','Orientation in degrees',...
    %                   'pos',[10 110 145 20],'parent',h, 'HorizontalAlignment', 'Left');


                P.H = H;  
                set(H(3), 'Callback', {@Pix2Or, P});
                set(H(2), 'Callback', {@Pix2Or, P});
                set(H(1), 'Callback', {@Or2Pix, P});
                uiwait(FG)
                Valx = str2double( get(H(2), 'String') ); 
                Valy = str2double( get(H(3), 'String') );

                close(FG)

            if ~isnan(Valx) && ~isnan(Valy)
                    OldBez = Bez;
                    Bez.P(Pnt).u = Valx;
                    Bez.P(Pnt).v = Valy;

                    Bez = UpdateLines( Pnt, Bez, OldBez);

            else
                errordlg('Invalid input!!!')
            end
         end
         Bez.P2POS = 0;
         Bez.P2VEC = 0;
         
%      else
%          
%             FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Edit', 'Position', [100 300 200 150]); 
% 
%             uc = uicontrol('Style','Toggle','String','Cancel',...
%                 'pos',[120 10 50 20],'parent',FG);
%             u0 = uicontrol('Style','Pushbutton','String','OK',...
%                 'pos',[65 10 50 20],'parent',FG);
% 
% 
%             u2 = uicontrol('Style','Pushbutton','String','Rotate',...
%                 'pos',[65 35 50 20],'parent',FG);
%             u3 = uicontrol('Style','Pushbutton','String','Shift',...
%                 'pos',[120 35 50 20],'parent',FG);
% 
% 
%             u4 = uicontrol('Style','Pushbutton','String','FlipLR',...
%                 'pos',[10 60 50 20],'parent',FG);
%             u5 = uicontrol('Style','Pushbutton','String','FlipUD',...
%                 'pos',[65 60 50 20],'parent',FG);
% 
%             uicontrol('Style','Text','String','Line thickness(px)',...
%                 'pos',[10 85 110 17],'parent',FG, 'FontSize', 10);
%             u6 = uicontrol('Style','Edit','String', num2str(Bez.Wid),...
%                 'pos',[125 85 30 20],'parent',FG);
% 
% 
% 
% 
%             Hdl = guihandles(FG);
%             Hdl.Bez = Bez;
%             
%             Hdl.PPD = PPD;
%             Hdl.Res = 0;
%             Hdl.FG = FG;
%             guidata(FG, Hdl)
% 
%             set(u2, 'Callback', {@rotate, FG});
%             set(u3, 'Callback', {@ShiftInputMenu, FG});
%             set(u4, 'Callback', {@fliplr, FG});
%             set(u5, 'Callback', {@flipud, FG});
% 
%             set(u6, 'Callback', {@linewide, FG});
%             set(u0, 'Callback', {@CloseMenu, FG});
%             set(uc, 'Callback', {@CloseMenu, FG});
% 
% 
%             uiwait(FG)
%             if ishandle(FG)
%                 Hdl = guidata(FG);
%                 if Hdl.Res
%                     Bez = Hdl.Bez;
%                 end
%      %       Res = get(h, 'SelectedObject');
%                 close(FG)
%             end 

         
     end
     
   function rotate( hObject, eventdata, FH) 
        Handles = guidata(FH);
        Bez = Handles.Bez; 
        OldBez = Bez;
        len = length(Bez.P);
        A = str2double(inputdlg('Angle'));
        Angn = A/180 * pi;
        
        for j = 1:len
            oldx = Bez.P(j).x;
            oldy = Bez.P(j).y;
            Ang = atan2(oldy, oldx); %old angle
            Rp = sqrt(oldx^2 + oldy^2); %radius of point
            Bez.P(j).x = cos(Angn + Ang)*Rp;
            Bez.P(j).y = sin(Angn + Ang)*Rp;

            oldu = Bez.P(j).u;
            oldv = Bez.P(j).v;                  
            Ang = atan2(oldv, oldu); %old angle
            Rp = sqrt(oldu^2 + oldv^2); %radius of point
            Bez.P(j).u = cos(Angn + Ang)*Rp;
            Bez.P(j).v = sin(Angn + Ang)*Rp;
        end

        Handles.Bez = UpdateLines( 0, Bez, OldBez);
        guidata(FH, Handles)
       

  function deletepos( hObject, eventdata, FH)   
        Handles = guidata(FH);
        Bez = Handles.Bez;    
        Bez.P2POS = Handles.Pnt;      
        Handles.Bez = DeletePoint(Bez);
        guidata(FH, Handles)
        
    function addpoint( hObject, eventdata, FH)   
        Handles = guidata(FH);
        Bez = Handles.Bez;    
        
        %get selected point
        Pnt = Handles.Pnt; 
        %plot two alternative points
        if Pnt == 1
            Pbefore.x = Bez.P(1).x - (Bez.P(1).u - Bez.P(1).x)/2;
            Pbefore.y = Bez.P(1).y - (Bez.P(1).v - Bez.P(1).y)/2;
            
            Line = Bez.L{Pnt};
            Pos = round(length(Line)/2);
            Pafter.x = Line(Pos,1);
            Pafter.y = Line(Pos,2);
            
        elseif Pnt > 1 && Pnt < length(Bez.P)
            Line = Bez.L{Pnt-1};
            Pos = round(length(Line)/2);
            Pbefore.x = Line(Pos,1);
            Pbefore.y = Line(Pos,2);
            
            Line = Bez.L{Pnt};
            Pos = round(length(Line)/2);
            Pafter.x = Line(Pos,1);
            Pafter.y = Line(Pos,2);
            
        elseif Pnt == length(Bez.P)
            Line = Bez.L{Pnt-1};
            Pos = round(length(Line)/2);
            Pbefore.x = Line(Pos,1);
            Pbefore.y = Line(Pos,2); 
            
            Pafter.x = (Bez.P(Pnt).x + Bez.P(Pnt).u)/2;
            Pafter.y = (Bez.P(Pnt).y + Bez.P(Pnt).v)/2;
            
        end
        cgpencol(1,1,0)
        cgellipse(Pbefore.x, Pbefore.y,4,4)
        cgellipse(Pafter.x, Pafter.y,4,4)
        cgflip
        cgellipse(Pbefore.x, Pbefore.y,4,4)
        cgellipse(Pafter.x, Pafter.y,4,4)    
        
        P = [Pbefore Pafter];
        %let user choose
        bd = 0;
        while ( bd ~= 1 ) %wait for button press 
            pause(0.01)
            [x,y, bd] = cgmouse;
        end
        %which point was selected?
        for i = 1:2
            dx2 = (P(i).x - x)^2;
            dy2 = (P(i).y - y)^2;
            if sqrt(dx2 + dy2) < 10              
                cgpencol(1,0,1)
                cgellipse(P(i).x, P(i).y,4,4)
                cgflip
                cgellipse(P(i).x, P(i).y,4,4)
                
                if i-1 == 1, 
                    j = 1;
                    Side = 1; %after!
                else
                    j = 2;
                    Side = 0; %before!
                end
                cgpencol(0,0,0)
                cgellipse(P(j).x, P(j).y,4,4)
                cgflip
                cgellipse(P(j).x, P(j).y,4,4)
                
            end
        end
        P(j) = [];
        
        %add the point and connecting line segment
        Oldbez = Bez;
        Len = length(Bez.P);
        if Pnt < Len
            Pnt = Pnt + Side;
            Bez.P(Pnt+1:Len+1) = Bez.P(Pnt:Len); %shift the points 
            Bez.P(Pnt).x = P.x; %insert the new point
            Bez.P(Pnt).y = P.y;
            
            if Pnt > 1
                %calculate derivative of point in original line
                Line = Bez.L{Pnt-1};
                Pos = round(length(Line)/2);
                dx = mean(diff(Line(Pos-1:Pos+1,1)))*25;
                dy = mean(diff(Line(Pos-1:Pos+1,2)))*25;
                
                Bez.P(Pnt).u = P.x + dx;
                Bez.P(Pnt).v = P.y + dy;
            else
                Bez.P(1).u = Bez.P(2).u + P.x - Bez.P(2).x; 
                Bez.P(1).v = Bez.P(2).v + P.y - Bez.P(2).y;
            end
            
        elseif Side == 0
            Bez.P(Len+1) = Bez.P(Len); %shift the last point 
            Bez.P(Len).x = P.x; %insert the new point
            Bez.P(Len).y = P.y;
            %calculate derivative of point in original line
            Line = Bez.L{Len-1};
            Pos = round(length(Line)/2);
            dx = mean(diff(Line(Pos-1:Pos+1,1)))*25;
            dy = mean(diff(Line(Pos-1:Pos+1,2)))*25;
            
            Bez.P(Len).u = P.x + dx; 
            Bez.P(Len).v = P.y + dy;
            
        else
            Bez.P(Len+1).x = P.x; %insert the new point
            Bez.P(Len+1).y = P.y;
            Bez.P(Len+1).u = Bez.P(Len).u + P.x - Bez.P(Len).x; 
            Bez.P(Len+1).v = Bez.P(Len).v + P.y - Bez.P(Len).y;
        end
        
       %update the bezier
       Handles.Bez = UpdateLines( 0, Bez, Oldbez);
        
        guidata(FH, Handles)
        
     
  function fliplr( hObject, eventdata, FH)
                  
      Handles = guidata(FH);
      Bez = Handles.Bez;

     OldBez = Bez;
     len = length(Bez.P);
     for j = 1:len
         oldx = Bez.P(j).x;
         %oldy = Bez.P(j).y;
         oldu = Bez.P(j).u;
         %oldv = Bez.P(j).v;

         Bez.P(j).x = -oldx;
         %Bez.P(j).y = oldy;
         Bez.P(j).u = -oldu;
         %Bez.P(j).v = oldv;
     end

     
     Handles.Bez = UpdateLines( 0, Bez, OldBez);  %just shift the whole bezier
     guidata(FH, Handles)
     
 function flipud( hObject, eventdata, FH)
                  
      Handles = guidata(FH);
      Bez = Handles.Bez;

     OldBez = Bez;
     len = length(Bez.P);
     for j = 1:len
         %oldx = Bez.P(j).x;
         oldy = Bez.P(j).y;
         %oldu = Bez.P(j).u;
         oldv = Bez.P(j).v;

         %Bez.P(j).x = -oldx;
         Bez.P(j).y = -oldy;
         %Bez.P(j).u = -oldu;
         Bez.P(j).v = -oldv;
     end

     
     Handles.Bez = UpdateLines( 0, Bez, OldBez);  %just shift the whole bezier
     guidata(FH, Handles)
     
  function CloseMenu( hObject, eventdata, FH)
      
      Handles = guidata(FH);
      STR = get(hObject, 'String');
      if strcmp(STR, 'OK')
          Handles.Res = 1;
          guidata(FH, Handles)
      end
      uiresume(FH)
         

 function ShiftInputMenu(hObject, eventdata, FH)
       
            Handles = guidata(FH);
            Bez = Handles.Bez;
            PPD = Handles.PPD;
            Pnt = Handles.Pnt;
     
            strx = num2str(Bez.P(Pnt).x);
            stry = num2str(Bez.P(Pnt).y);
            strDx = num2str(Bez.P(Pnt).x / PPD);
            strDy = num2str(Bez.P(Pnt).y / PPD);
            strPPD = num2str(PPD);
            
     FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Shift', ...
                'Position', [100 300 210 210], 'Resize', 'off', 'WindowStyle', 'modal');

            uicontrol('Style','Toggle','String','OK',...
                 'pos',[150 35 50 20],'parent',FG, 'Callback', {@ShiftCall, FG});
             
            uicontrol('Style','Text','String','Vertical position in pixels',...
                  'pos',[10 60 145 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(2) = uicontrol('Style','Edit','String', stry,...
                  'pos',[160 60 40 20],'parent',FG);
            uicontrol('Style','Text','String','Horizontal position in pixels',...
                  'pos',[10 85 145 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(3) = uicontrol('Style','Edit','String', strx,...
                  'pos',[160 85 40 20],'parent',FG);
            uicontrol('Style','Text','String','Vertical position in degrees',...
                  'pos',[10 110 145 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(4) = uicontrol('Style','Edit','String', strDy,...
                  'pos',[160 110 40 20],'parent',FG);
            uicontrol('Style','Text','String','Horizontal position in degrees',...
                  'pos',[10 135 145 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(5) = uicontrol('Style','Edit','String', strDx,...
                  'pos',[160 135 40 20],'parent',FG);
            uicontrol('Style','Text','String','Pixels per degree',...
                  'pos',[10 160 145 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(8) = uicontrol('Style','Edit','String', strPPD,...
                  'pos',[160 160 40 20],'parent',FG);
              
            u(6) = uicontrol('Style','pushbutton','String','Shiftline',...
                  'pos',[10 35 50 20],'parent',FG, 'HorizontalAlignment', 'Left');
            u(7) = uicontrol('Style','pushbutton','String','Shiftpoint',...
                  'pos',[65 35 50 20],'parent',FG, 'HorizontalAlignment', 'Left');
            
            set(u(2), 'Callback', {@Pix2Deg, u(4), FH});
            set(u(3), 'Callback', {@Pix2Deg, u(5), FH});
            set(u(4), 'Callback', {@Deg2Pix, u(2), FH});
            set(u(5), 'Callback', {@Deg2Pix, u(3), FH});
            set(u(8), 'Callback', {@ChangePPD, FH});
            
            set(u(6), 'Callback', {@Shiftline, FH});
            set(u(7), 'Callback', {@Shiftpoint, FH});
            
            Handles.RES = 0;
            Handles.u = u;
          
            guidata(FH, Handles)  


            uiwait(FG)  
            close(FG)

              
            
 function Shiftline(hObject, eventdata, FH) 
     
     Handles = guidata(FH);
     Valx = str2double( get(Handles.u(3), 'String') );
     Valy = str2double( get(Handles.u(2), 'String') );
     Bez = Handles.Bez;
     Pnt = Handles.Pnt;
     len = length(Bez.P);

     oldx = Bez.P(Pnt).x;
     oldy = Bez.P(Pnt).y;
     %oldu = Bez.P(Pnt).u;
     %oldv = Bez.P(Pnt).v;
     dx = round(Valx) - oldx;
     dy = round(Valy) - oldy;

     OldBez = Bez;
     for j = 1:len
         oldx = Bez.P(j).x;
         oldy = Bez.P(j).y;
         oldu = Bez.P(j).u;
         oldv = Bez.P(j).v;

         Bez.P(j).x = oldx + dx;
         Bez.P(j).y = oldy + dy;
         Bez.P(j).u = oldu + dx;
         Bez.P(j).v = oldv + dy;
     end

     Handles.Bez = UpdateLines( 0, Bez, OldBez);  %just shift the whole bezier
     guidata(FH, Handles)
     
 
 function Shiftpoint(hObject, eventdata, FH)
     global CLOSED
     
     Handles = guidata(FH);
     Valx = str2double( get(Handles.u(3), 'String') );
     Valy = str2double( get(Handles.u(2), 'String') );
     Bez = Handles.Bez;
     Pnt = Handles.Pnt;
     len = length(Bez.P);
     
     OldBez = Bez;
     oldx = Bez.P(Pnt).x;
     oldy = Bez.P(Pnt).y;
     oldu = Bez.P(Pnt).u;
     oldv = Bez.P(Pnt).v;
     dx = round(Valx) - oldx;
     dy = round(Valy) - oldy;
     
     Bez.P(Pnt).x = oldx + dx;
     Bez.P(Pnt).y = oldy + dy;
     Bez.P(Pnt).u = oldu + dx;
     Bez.P(Pnt).v = oldv + dy;


     if CLOSED
         if Pnt == 1
             Bez.P(len).x = Bez.P(Pnt).x;
             Bez.P(len).y = Bez.P(Pnt).y;
             Bez.P(len).u = Bez.P(Pnt).u;
             Bez.P(len).v = Bez.P(Pnt).v;
         end
     end

     Handles.Bez = UpdateLines( Pnt, Bez, OldBez);
    guidata(FH, Handles)
     
 function linewide( hObject, eventdata, FH)
     
     Str = get(hObject, 'String');
      var = str2double(Str);
 if ~isnan(var) && round(var) > 0
     
     Handles = guidata(FH);
     Bez = Handles.Bez; 
     OldBez = Bez;
     Bez.Wid = round(var);
     Handles.Bez = UpdateLines( 0, Bez, OldBez);

     guidata(FH, Handles)
 end 

  function linecol( hObject, eventdata, FH)
       
     
    
     Handles = guidata(FH);
     Bez = Handles.Bez; 
     c = uisetcolor(Bez.Col);
     
     OldBez = Bez;
     Bez.Col = c;
     Handles.Bez = UpdateLines( 0, Bez, OldBez);
     guidata(FH, Handles)

     
 function ShiftCall( hObject, eventdata, FH)
      Handles = guidata(FH);
      STR = get(hObject, 'String');
      if strcmp(STR, 'OK')
          Handles.Res = 1;
          guidata(FH, Handles)
      end
      uiresume(FH)
     
 function ChangePPD(hObject, eventdata,  FH)
     Handles = guidata(FH);
     Str = get(hObject, 'String');
     Val = str2double(Str);
     if ~isnan(Val)

         u = Handles.u;
         Str = get(u(2), 'String');
         pix = str2double(Str); 
         set(u(4), 'String', num2str(pix/ Val))
         Str = get(u(3), 'String');
         pix = str2double(Str); 
         set(u(5), 'String', num2str(pix /Val))         
         
         Handles.PPD = Val;
         guidata(FH, Handles)
     end
     
     
 function Deg2Pix(hObject, eventdata, OH, FH)
     Handles = guidata(FH);
     PPD = Handles.PPD;
     Str = get(hObject, 'String');
     Val = str2double(Str);
     if ~isnan(Val)
         Val = Val * PPD;
         set(OH, 'String', num2str(Val))
     end
     
     
 function Pix2Deg(hObject, eventdata, OH, FH)
     Handles = guidata(FH);
     PPD = Handles.PPD;
     Str = get(hObject, 'String');
     Val = str2double(Str);
     if ~isnan(Val)
         Val = Val / PPD;
         set(OH, 'String', num2str(Val))
     end
     
 function Or2Pix(hObject, eventdata, PH)
     Or = str2double(get(hObject, 'String'));
     u = str2double(get(PH.H(2), 'String'));
     v = str2double(get(PH.H(3), 'String'));
     x = PH.x;
     y = PH.y;
     L = sqrt((u - x)^2 + (v - y)^2);
     Rad = Or / 180 * pi;
     u = round(cos(Rad)* L + x);
     v = round(sin(Rad)* L + y);
     set(PH.H(2), 'String', num2str(u))
     set(PH.H(3), 'String', num2str(v))
     
 function Pix2Or(hObject, eventdata, PH)
     %Or = str2double(get(PH.H(1), 'String'));
     u = str2double(get(PH.H(2), 'String'));
     v = str2double(get(PH.H(3), 'String'));
     x = PH.x;
     y = PH.y;   
     theta = atan2(v - y, u - x ) / pi * 180;
     set(PH.H(1), 'String', num2str(theta, '%5.1f') )
     
     
 function Bez = DeletePoint(Bez)
     
     len = length(Bez.P);
     if len > 2
         Pnt = Bez.P2POS;

         OldBez = Bez;
         Bez.P(Pnt) = [];
         if Pnt == len  %if closed you won't get the last point     
             Bez.L(Pnt-1) = [];
             Pnt = 0;        
         else
             Bez.L(Pnt) = [];
         end

         Bez = UpdateLines( Pnt, Bez, OldBez);
     else
         errordlg('Just delete this bezier!!!', 'cgbezier error')
     end
     Bez.P2POS = 0;
     
     
     
 function Bez = Mouseedit(x, y, i, SEL, Bez, In)
     
     global CLOSED 
     bd = 1;
     len = length(Bez.P);
     SHIFT = 0;
     ROT = 0;
     
     switch In
         case 1
             SHIFT = 1;
         case 2
             ROT = 1;
         otherwise
     end
    
     if SEL == 1 %a line position has been selected
        while bd == 1 %wait for button release
            pause(0.01)
            [x1,y1, bd] = cgmouse; 
        end 

        if  ~(x == x1 && y == y1) %new points differ from old, shifting position
            oldx = Bez.P(i).x;
            oldy = Bez.P(i).y;
            oldu = Bez.P(i).u;
            oldv = Bez.P(i).v;
            dx = x1 - oldx;
            dy = y1 - oldy;
            
            OldBez = Bez;
            
            if SHIFT
                
                for j = 1:len
                    oldx = Bez.P(j).x;
                    oldy = Bez.P(j).y;
                    oldu = Bez.P(j).u;
                    oldv = Bez.P(j).v;
                    Bez.P(j).x = oldx + dx;
                    Bez.P(j).y = oldy + dy;
                    Bez.P(j).u = oldu + dx;
                    Bez.P(j).v = oldv + dy;
                end
                
                Bez = UpdateLines( 0, Bez, OldBez);
                
            elseif ROT
                Ango = atan2(oldy, oldx); %old angle
                Angn = atan2(y1, x1); %new angle
                for j = 1:len
                    oldx = Bez.P(j).x;
                    oldy = Bez.P(j).y;
                    Ang = atan2(oldy, oldx) - Ango; %old angle
                    Rp = sqrt(oldx^2 + oldy^2); %radius of point
                    Bez.P(j).x = cos(Angn + Ang)*Rp;
                    Bez.P(j).y = sin(Angn + Ang)*Rp;
                    
                    oldu = Bez.P(j).u;
                    oldv = Bez.P(j).v;                  
                    Ang = atan2(oldv, oldu) - Ango; %old angle
                    Rp = sqrt(oldu^2 + oldv^2); %radius of point
                    Bez.P(j).u = cos(Angn + Ang)*Rp;
                    Bez.P(j).v = sin(Angn + Ang)*Rp;
                end
                
                Bez = UpdateLines( 0, Bez, OldBez);
                
            else
                Bez.P(i).x = x1;
                Bez.P(i).y = y1;
                Bez.P(i).u = oldu + dx;
                Bez.P(i).v = oldv + dy;
                
                if CLOSED 
                    if i == 1
                        Bez.P(len).x = x1;
                        Bez.P(len).y = y1;
                        Bez.P(len).u = Bez.P(i).u;
                        Bez.P(len).v = Bez.P(i).v;
                    end
                end
                Bez = UpdateLines( i, Bez, OldBez);

            end

        end

    elseif SEL == 2
        while bd == 1 %wait for button release
            pause(0.01)
            [u1,v1, bd] = cgmouse;  
        end 

        oldu = Bez.P(i).u;
        oldv = Bez.P(i).v;
        du = u1 - oldu;
        dv = v1 - oldv;
        OldBez = Bez;
        
        if SHIFT
            
            for j = 1:len         
                oldx = Bez.P(j).x;
                oldy = Bez.P(j).y;
                oldu = Bez.P(j).u;
                oldv = Bez.P(j).v;
                Bez.P(j).x = oldx + du;
                Bez.P(j).y = oldy + dv;
                Bez.P(j).u = oldu + du;
                Bez.P(j).v = oldv + dv;
            end
            Bez = UpdateLines( 0, Bez, OldBez);
            
            
        else
            Bez.P(i).u = u1;
            Bez.P(i).v = v1;
            if CLOSED 
%                 if i == 1
                    Bez.P(len).u = u1;
                    Bez.P(len).v = v1;                    
%                 elseif i == len
%                     Bez.P(1).u = u1;
%                     Bez.P(1).v = v1;
%                 end
            end
            Bez = UpdateLines( i, Bez, OldBez);

        end
        
    end

     
function Bez = UpdateLines( Ip, Bez, OldBez)
    
    global CLOSED
    numP = length(Bez.P); %number of points
    numL = numP - 1;  %number of lines
    
    if Ip == 0
        
         cgpencol(0,0,0)
         for j = 1:2
             cgpenwid(1)
             for i = 1:length(OldBez.P)
                 cgellipse(OldBez.P(i).x, OldBez.P(i).y, 4,4)
             end
             for i = 1:length(OldBez.P)
                 cgellipse(OldBez.P(i).u, OldBez.P(i).v, 4,4)
             end
             cgpenwid(OldBez.Wid)
             for i = 1:length(OldBez.L)
                 LEN = length(OldBez.L{i});
                 cgdraw(OldBez.L{i}(1:LEN-1,1), OldBez.L{i}(1:LEN-1,2), OldBez.L{i}(2:LEN,1), OldBez.L{i}(2:LEN,2) );
             end
             cgflip
         end
       
       Bez.L = [];
       for j = 1:numL
            P = Bez.P(j:j+1);
            
            Bez.L{j} = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                      (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                      (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);

       end
       
       for j = 1:2
           cgpenwid(Bez.Wid)
           cgpencol(Bez.Col(1), Bez.Col(2), Bez.Col(3))
           for i = 1:length(Bez.L)
               LEN = length(Bez.L{i});
              cgdraw(Bez.L{i}(1:LEN-1,1), Bez.L{i}(1:LEN-1,2), Bez.L{i}(2:LEN,1), Bez.L{i}(2:LEN,2) );
           end
           
           cgpenwid(1)
           cgpencol(0,0.7,1)
           for i = 1:length(Bez.P)
                cgellipse(Bez.P(i).x, Bez.P(i).y, 4,4)
           end
           cgpencol(0,1,0)
           for i = 1:length(Bez.P)
                cgellipse(Bez.P(i).u, Bez.P(i).v, 4,4)
           end

           cgflip
       end
    else
        
        cgpenwid(1)
        cgpencol(0,0,0)
        cgellipse(OldBez.P(Ip).x, OldBez.P(Ip).y,4,4)
        cgellipse(OldBez.P(Ip).u, OldBez.P(Ip).v,4,4)
        cgflip
        cgellipse(OldBez.P(Ip).x, OldBez.P(Ip).y,4,4)
        cgellipse(OldBez.P(Ip).u, OldBez.P(Ip).v,4,4)
        
        if Ip < numP
            cgpenwid(Bez.Wid)
            P = Bez.P(Ip:Ip+1);
            Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                      (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                      (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);
                  
            
            cgpencol(0,0,0) %clear old line after selected point
            cgdraw(OldBez.L{Ip}(1:end-1,1), OldBez.L{Ip}(1:end-1,2), OldBez.L{Ip}(2:end,1), OldBez.L{Ip}(2:end,2));
            cgflip
            cgdraw(OldBez.L{Ip}(1:end-1,1), OldBez.L{Ip}(1:end-1,2), OldBez.L{Ip}(2:end,1), OldBez.L{Ip}(2:end,2));

            cgpencol(Bez.Col(1), Bez.Col(2), Bez.Col(3))            
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            cgflip
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            Bez.L(Ip) = {Line};
            
        elseif   length(OldBez.P) > numP  %case in which second last point was deleted
            cgpencol(0,0,0) %clear old line after selected point
            cgdraw(OldBez.L{Ip}(1:end-1,1), OldBez.L{Ip}(1:end-1,2), OldBez.L{Ip}(2:end,1), OldBez.L{Ip}(2:end,2));
            cgflip
            cgdraw(OldBez.L{Ip}(1:end-1,1), OldBez.L{Ip}(1:end-1,2), OldBez.L{Ip}(2:end,1), OldBez.L{Ip}(2:end,2));            
            
        end   
        if Ip > 1
            cgpenwid(OldBez.Wid)
            P = Bez.P(Ip-1:Ip);
            Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                      (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                      (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);

            cgpencol(0,0,0) %clear old line before selected point
            cgdraw(OldBez.L{Ip-1}(1:end-1,1), OldBez.L{Ip-1}(1:end-1,2), OldBez.L{Ip-1}(2:end,1), OldBez.L{Ip-1}(2:end,2));
            cgflip
            cgdraw(OldBez.L{Ip-1}(1:end-1,1), OldBez.L{Ip-1}(1:end-1,2), OldBez.L{Ip-1}(2:end,1), OldBez.L{Ip-1}(2:end,2));

            cgpencol(Bez.Col(1), Bez.Col(2), Bez.Col(3))
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            cgflip
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            Bez.L(Ip-1) = {Line}; 

        end

        if Ip == 1 && CLOSED
              cgpenwid(OldBez.Wid)
              len = length(Bez.P);
              P = Bez.P(len-1:len); 
              Line = defbezier(P(1).x, P(1).y, P(2).x, P(2).y,...
                      (P(1).u-P(1).x)*2, (P(1).v-P(1).y)*2,...
                      (P(2).u-P(2).x)*2, (P(2).v-P(2).y)*2);

            cgpencol(0,0,0) %clear old line +
            cgdraw(OldBez.L{numL}(1:end-1,1), OldBez.L{numL}(1:end-1,2), OldBez.L{numL}(2:end,1), OldBez.L{len-1}(2:end,2));
            cgflip
            cgdraw(OldBez.L{numL}(1:end-1,1), OldBez.L{numL}(1:end-1,2), OldBez.L{numL}(2:end,1), OldBez.L{len-1}(2:end,2));

            cgpenwid(Bez.Wid)
            cgpencol(Bez.Col(1), Bez.Col(2), Bez.Col(3)) 
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            cgflip
            cgdraw(Line(1:end-1,1), Line(1:end-1,2), Line(2:end,1), Line(2:end,2));
            Bez.L(len-1) = {Line}; 

        end
        
        Pnts = Ip-1:Ip+1;
        if Ip == numP
            Pnts(3) = [];
        
        elseif CLOSED && Ip == 1
            Pnts(1) = numP;
            
        elseif Ip == 1
            Pnts(1) = [];
        end
            
            cgpenwid(1)
            for j = 1:2
                for i = Pnts 
                    cgpencol(0,1,0)
                    cgellipse(Bez.P(i).u, Bez.P(i).v,4,4)
                    cgpencol(0,0.7,1)
                    cgellipse(Bez.P(i).x, Bez.P(i).y,4,4)
                end
                cgflip
            end
        
        
    end  
    
function Line = defbezier(x0, y0, x1, y1, x0d, y0d, x1d, y1d)
t0 = 0; 
t1 = 1;

a(1)=2*x0-2*x1+x0d+x1d;
a(2)=-3*x0+3*x1-2*x0d-x1d;
a(3)=x0d;
a(4)=x0;

b(1)=2*y0-2*y1+y0d+y1d;
b(2)=-3*y0+3*y1-2*y0d-y1d;
b(3)=y0d;
b(4)=y0;

Lx = [];
Ly = [];
dist = [];
[Lx, Ly, dist] = connect(t0,t1,x0,y0,x1,y1, a, b, Lx, Ly, dist);
[~, Indx] = sort(dist);

Line = [Lx(Indx).', Ly(Indx).'];
Line = [[x0, y0]; Line; [x1,y1]];

 
function [Lx, Ly, dist] = connect( t0, t1, x0, y0, x1, y1, a, b, Lx, Ly, dist)

if x0>x1+2 || x0<x1-2 || y0>y1+2 || y0<y1-2
    th = (t0+t1)/2;
    th2 = th*th;
    th3 = th*th2;
    dist = [dist th];
    xh=((0.5+a(1)*th3+a(2)*th2+a(3)*th+a(4)));
    yh=((0.5+b(1)*th3+b(2)*th2+b(3)*th+b(4)));
    Lx = [Lx xh];
    Ly = [Ly yh];
    
    [Lx, Ly, dist] = connect( t0, th, x0, y0, xh, yh, a, b, Lx, Ly, dist);
    [Lx, Ly, dist] = connect( th, t1, xh, yh, x1, y1, a, b, Lx, Ly, dist);
    
end

    
    


