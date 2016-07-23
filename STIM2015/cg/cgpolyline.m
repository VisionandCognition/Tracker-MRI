function Polyline = cgpolyline( varargin )
%function Polygon = cgPolygon( varargin)
%Polygon.P.x    :array of x and y positions 
%         .y    
%         .f    : true or false; filled polygon or just lines
%         .w    :line width
%         .c    : color [r, g, b] (0-1)
%05-06-2008
%C van der Togt
%Vision and Cognition

if nargin > 0
    Polyline = varargin{1};

    Mode = 0;  %adds to existing curve
else
    Polyline = [];  %new curve
    Mode = 0;
end

if nargin > 1 %must be 'E' to go in edit mode
    Mode = varargin{2};
end


A = cgFlip('v');
if A == -2
    disp('Open a Cogent window before using this function!!!');
    
    return
end


cgPenWid(1)
cgpencol(1,1,1)



if ( isfield(Polyline, 'P') && length(Polyline.P) > 1 )


        P = Polyline.P;
        X = [P(:).x];
        Y = [P(:).y];
        fill = Polyline.f;
        wid = Polyline.w;
        col = Polyline.c;
        
        for i = 1:2
            cgpencol(col(1),col(2), col(3))
            cgPenWid(wid)
            if fill
                cgpolygon(X, Y)
            else
                x1 = X(1:end-1);
                x2 = X(2:end);
                y1 = Y(1:end-1);
                y2 = Y(2:end);
                cgdraw(x1, y1, x2, y2)
            end


            if Mode == 'P'
                return
            elseif Mode == 'D'
                cgflip
                return
            else
                cgPenWid(1)
                cgpencol(0, 0.7, 0.7)
                for j = 1:length(P)
                    cgEllipse(P(j).x, P(j).y,4,4)
                end
                cgFlip
            end
        end

elseif Mode == 'E';
        disp('No Polyline!!!');
        return 
else
    %initialize values for new Polyline
    Polynew.f = false;  
    Polynew.w = 1;
    Polynew.c = [1 1 1];
    fill = false;
    wid = 1;
    col = [1 1 1];
    P = []; 
end


cgKeyMap(); %clear keymap
ESC = 0;
% K_SHIFT = 0;
% K_CTRL = 0;
[x,y, bd] = cgmouse;
SEL = false;

while ~ESC && (Mode == 0 || Mode == 'E')

    while bd ~= 1 && ~ESC %wait for button press or escape or close curve (C key)
        pause(0.01)
        [kd, kp] = cgKeyMap();
        ESC = kp(1);
        
%         if ~K_SHIFT %catch shift press
%             K_SHIFT = kp(42); %has the shift key been pressed
%             %Shift whole bezier
%         end
%         if ~K_CTRL
%             K_CTRL = kp(29); %Has left CRTL key been pressed,
%             %value editing
%         end
        [x,y, bd] = cgmouse;
    end
    if Mode == 0 && ~ESC %new and add mode
        cgpencol(0,1,1)
        cgEllipse(x,y,4,4)
        cgFlip
        cgEllipse(x,y,4,4)
         %save the points for position 
         i = length(P) + 1;
         P(i).x = x;
         P(i).y = y;
         if i > 1
             for j = 1:2
                 cgpencol(col(1),col(2), col(3))
                 cgPenWid(1)
                 X = [P(i-1:i).x];
                 Y = [P(i-1:i).y];

                 x1 = X(1);
                 x2 = X(2);
                 y1 = Y(1);
                 y2 = Y(2);
                 cgdraw(x1, y1, x2, y2)

                 cgFlip
             end
         end

        while bd == 1 %wait for button release 
            pause(0.01)
            [u,v, bd] = cgmouse;  
        end

    elseif Mode == 'E' && ~ESC
        if ~ESC %if not escaped evaluate whether returned point
                %corresponds with the location of one of the bezier points
            len = length(P);
            cgPenWid(1)
            for i = 1:len
                dx2 = (x-P(i).x)^2;
                dy2 = (y-P(i).y)^2;
                if sqrt(dx2 + dy2) < 4
                    cgpencol(1,0,1)
                    cgEllipse(P(i).x, P(i).y,4,4)
                    cgFlip
                    cgEllipse(P(i).x, P(i).y,4,4)
                    SEL = true; %a point is selected
                    break               
                end

            end
        end
        
        while bd == 1 %wait for button release 
            pause(0.01)
            [x1,y1, bd] = cgmouse;  
        end
        
        [kd, kp] = cgKeyMap();
        K_SHIFT = kd(42); %is the shift key pressed
        K_CTRL = kd(29); %is left CRTL key pressed  
        
       if SEL && x ~= x1 && y ~= y1
           P = mousedit(i, P, x1, y1, col, wid, fill, K_SHIFT);
           Polyline.P = P;
        %   K_SHIFT = false;
           
       elseif SEL && K_CTRL
           Polyline = menuedit(i, Polyline);
           P = Polyline.P;
           col = Polyline.c;
           fill = Polyline.f;
           wid = Polyline.w;
        %   K_CTRL = false;
           
       elseif SEL
           cgpencol(0,0.7,0.7)
           cgEllipse(P(i).x, P(i).y,4,4)
           cgFlip
           cgEllipse(P(i).x, P(i).y,4,4)
           
       end

       SEL = false;
       
    end
    
end

if Mode == 0
    Polynew.P = P;
    Polyline = Polynew;
end

function Polyl = menuedit(i, Polyl)

        global Par;
        
        col = Polyl.c;
        wid = Polyl.w;
        fill = Polyl.f;
        
        if isfield(Par, 'PixPerDeg')
            PPD = Par.PixPerDeg;
        else
            PPD = 25;
        end
        
        FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Edit', 'Position', [100 600 175 145]); 
         
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
        u10 = uicontrol('Style','Radiobutton','String','Fill',...
            'pos',[120 60 50 20],'Value', fill, 'parent',FG);
        
        

        uicontrol('Style','Text','String','Line thickness(px)',...
            'pos',[10 86 110 18],'parent',FG, 'FontSize', 10);
        u6 = uicontrol('Style','Edit','String', wid,...
            'pos',[125 85 30 20],'parent',FG);
        uicontrol('Style','Text','String','Color(rgb)',...
            'pos',[10 111 65 18],'parent',FG, 'FontSize', 10);
        u7 = uicontrol('Style','Edit','String', col(1),...
            'pos',[80 110 25 20],'parent',FG);
        u8 = uicontrol('Style','Edit','String', col(2),...
            'pos',[105 110 25 20],'parent',FG);
        u9 = uicontrol('Style','Edit','String', col(3),...
            'pos',[130 110 25 20],'parent',FG);
       

        Hdl = guihandles(FG);
        Hdl.Polyl = Polyl;
        Hdl.Pnt = i;

        Hdl.Res = 0;
        
        Hdl.PPD = PPD;
        Hdl.FG = FG;
        guidata(FG, Hdl)
        
        set(u3, 'Callback',  {@ShiftInputMenu, FG});
        set(u4, 'Callback', {@fliplr, FG});
        set(u5, 'Callback', {@flipud, FG});
        set(u10, 'Callback', {@fillOO, FG});
        set(u7, 'Callback', {@pencolor, FG, 'r'} );
        set(u8, 'Callback', {@pencolor, FG, 'g'} );
        set(u9, 'Callback', {@pencolor, FG, 'b'} );
            
        set(u6, 'Callback', {@linewide, FG});
        set(u0, 'Callback', {@CloseMenu, FG});
        set(uc, 'Callback', {@CloseMenu, FG});
     
        uiwait(FG)
        if ishandle(FG)
            Hdl = guidata(FG);
            if Hdl.Res
                Polyl = Hdl.Polyl;
            end
            close(FG)
        end 
       
        
  function fliplr( hObject, eventdata, FH)
                  
      Handles = guidata(FH);
      Polyl = Handles.Polyl;
      P = Polyl.P;
      col = Polyl.c;
      wid = Polyl.w;
      fill = Polyl.f;
      
      OldP = P;
      for i = 1:length(P)
          P(i).x = -P(i).x;
      end
      
      for i = 1:2
          %delete old
          X = [OldP(:).x];
          Y = [OldP(:).y];
          deleteold(X,Y,wid,fill)

          %plot new
          X = [P(:).x];
          Y = [P(:).y];
          plotnew(X,Y,col,wid,fill)
          cgFlip
      end
      

     
     
     Polyl.P = P;
     Handles.Polyl = Polyl;
     guidata(FH, Handles)
     
 function flipud( hObject, eventdata, FH)
                  
      Handles = guidata(FH);
      Polyl = Handles.Polyl;
      P = Polyl.P;
      OldP = P;
      col = Polyl.c;
      wid = Polyl.w;
      fill = Polyl.f;
      
      for i = 1:length(P)
          P(i).y = -P(i).y;
      end
     
      for i = 1:2
          %delete old
          X = [OldP(:).x];
          Y = [OldP(:).y];
          deleteold(X,Y,wid,fill)

          %plot new
          X = [P(:).x];
          Y = [P(:).y];
          plotnew(X,Y,col,wid,fill)
          cgFlip
      end
      
      Polyl.P = P;
      Handles.Polyl = Polyl;
      guidata(FH, Handles)
     
function fillOO( hObject, eventdata, FH)
    Handles = guidata(FH);
    Polyl = Handles.Polyl;
    P = Polyl.P;
   
    col = Polyl.c;
    wid = Polyl.w;
    fill = Polyl.f;
    Val = get(hObject,'Value');
    if Val > 0
        newfill = true;
    else
        newfill = false;
    end
    for i = 1:2
        %delete old
        X = [P(:).x];
        Y = [P(:).y];
        deleteold(X,Y,wid,fill)

        %plot new
        plotnew(X,Y,col,wid,newfill)
        cgFlip
    end
    Polyl.f = newfill;
    Handles.Polyl = Polyl;
    guidata(FH, Handles)
    
function pencolor( hObject, eventdata, FH, COL)
    Handles = guidata(FH);
    Polyl = Handles.Polyl;
    P = Polyl.P;
    col = Polyl.c;
    newcol = col;
    wid = Polyl.w;
    fill = Polyl.f;
    STR = get(hObject, 'String');
    Val = str2double(STR);
    if ~isnan(Val) && Val >= 0 && Val <= 1
        switch COL
            case 'r'
                newcol(1) = Val; 
            case 'g'
                newcol(2) = Val;
            case 'b'
                newcol(3) = Val;
        end
        
        for i = 1:2
            %delete old
            X = [P(:).x];
            Y = [P(:).y];
            deleteold(X,Y,wid,fill)

            %plot new
            plotnew(X,Y,newcol,wid,fill)
            cgFlip
        end
        Polyl.c = newcol;
        Handles.Polyl = Polyl;
        guidata(FH, Handles)

    end
    
    
    
function linewide( hObject, eventdata, FH)
                       
      Handles = guidata(FH);
      Polyl = Handles.Polyl;
      
      STR = get(hObject, 'String');
      Val = str2double(STR);

      if ~isnan(Val) && round(Val) > 0
             P = Polyl.P;
             wid = Polyl.w;
             col = Polyl.c;
             fill = Polyl.f;
             newwid = round(Val);
             
             for i = 1:2
                 %delete old
                 X = [P(:).x];
                 Y = [P(:).y];
                 deleteold(X,Y,wid,fill)

                 %plot new
                 plotnew(X,Y,col,newwid,fill)
                 cgFlip
             end
            Polyl.w = newwid;
            Handles.Polyl = Polyl;
            guidata(FH, Handles)
      end
      
     
function CloseMenu( hObject, eventdata, FH)
      
      Handles = guidata(FH);
      STR = get(hObject, 'String');
      if strcmp(STR, 'OK')
          Handles.Res = 1;
          guidata(FH, Handles)
      end
      uiresume(FH)    
 
  function ShiftInputMenu( hObject, eventdata, FH)
      global Par
      
      Handles = guidata(FH);
      Polyl = Handles.Polyl;
      Pnt = Handles.Pnt;
      P = Polyl.P;
     
     if isfield(Par, 'PixPerDeg')
          PPD = Par.PixPerDeg;    
     else   
          PPD = 25;
     end
     
      strx = num2str(P(Pnt).x);
      stry = num2str(P(Pnt).y);
      strDx = num2str(P(Pnt).x / PPD);
      strDy = num2str(P(Pnt).y / PPD);
      strPPD = num2str(PPD);
            
     FG = figure('MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Shift', ...
                'Position', [100 600 210 210], 'Resize', 'off', 'WindowStyle', 'modal');

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
     
     Pnt = Handles.Pnt;
     Polyl = Handles.Polyl;
     P = Polyl.P;
     dx = Valx - P(Pnt).x;
     dy = Valy - P(Pnt).y; 
     OldP = P;
     wid = Polyl.w;
     col = Polyl.c;
     fill = Polyl.f;

     for j = 1:length(P)
         P(j).x = P(j).x + dx;
         P(j).y = P(j).y + dy;
     end
     for i = 1:2
         %delete old
         X = [OldP(:).x];
         Y = [OldP(:).y];
         deleteold(X,Y,wid,fill)

         %plot new
         X = [P(:).x];
         Y = [P(:).y];
         plotnew(X,Y,col,wid,fill)
         cgFlip
     end
     Polyl.P = P;
     Handles.Polyl = Polyl;
     guidata(FH, Handles)
     
 
 function Shiftpoint(hObject, eventdata, FH)
          
     Handles = guidata(FH);
     Valx = str2double( get(Handles.u(3), 'String') );
     Valy = str2double( get(Handles.u(2), 'String') );
     
     Pnt = Handles.Pnt;
     Polyl = Handles.Polyl;
     P = Polyl.P;
     dx = Valx - P(Pnt).x;
     dy = Valy - P(Pnt).y; 
     OldP = P;
     wid = Polyl.w;
     col = Polyl.c;
     fill = Polyl.f;
     
     P(Pnt).x = P(Pnt).x + dx;
     P(Pnt).y = P(Pnt).y + dy;
     for i = 1:2
         %delete old
         X = [OldP(:).x];
         Y = [OldP(:).y];
         deleteold(X,Y,wid,fill)

         %plot new
         X = [P(:).x];
         Y = [P(:).y];
         plotnew(X,Y,col,wid,fill)
         cgFlip
     end
     Polyl.P = P;
     Handles.Polyl = Polyl;
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
         set(OH, 'String', num2str(Val* PPD))
     end
     
     
 function Pix2Deg(hObject, eventdata, OH, FH)
     Handles = guidata(FH);
     PPD = Handles.PPD;
     Str = get(hObject, 'String');
     Val = str2double(Str);
     if ~isnan(Val)
         set(OH, 'String', num2str(Val /PPD))
     end
   

function P = mousedit(i, P, x, y, col, wid, fill, K_S)
    %determine which lines to change
    dx = x - P(i).x;
    dy = y - P(i).y; 
    OldP = P;
    if K_S
        for j = 1:length(P)
            P(j).x = P(j).x + dx;
            P(j).y = P(j).y + dy;
        end
        for i = 1:2
            %delete old
            X = [OldP(:).x];
            Y = [OldP(:).y];
            deleteold(X,Y,wid,fill)

            %plot new
            X = [P(:).x];
            Y = [P(:).y];
            plotnew(X,Y,col,wid,fill)
            cgFlip
        end
        
    else
        P(i).x = P(i).x + dx;
        P(i).y = P(i).y + dy;
        for i = 1:2
            %delete old
            X = [OldP(:).x];
            Y = [OldP(:).y];
            deleteold(X,Y,wid,fill)

            %plot new
            X = [P(:).x];
            Y = [P(:).y];
            plotnew(X,Y,col,wid,fill)
            cgFlip
        end

    end

                
function deleteold(X,Y, wid, fill)
        cgpencol(0,0,0)
        cgPenWid(1)
        for j = 1:length(X)
            cgEllipse(X(j), Y(j),4,4)
        end

        if fill
            cgPolygon(X, Y)
        else
            cgPenWid(wid)
            x1 = X(1:end-1);
            x2 = X(2:end);
            y1 = Y(1:end-1);
            y2 = Y(2:end);
            cgDraw(x1, y1, x2, y2)
        end

function plotnew(X,Y,col, wid, fill)
        cgpencol(col(1),col(2),col(3))
        cgPenWid(wid)
        if fill
            cgPolygon(X, Y)
        else
            cgPenWid(wid)
            x1 = X(1:end-1);
            x2 = X(2:end);
            y1 = Y(1:end-1);
            y2 = Y(2:end);
            cgDraw(x1, y1, x2, y2)
        end
        
        cgpencol(0,0.7,0.7)
        cgPenWid(1)
        for j = 1:length(X)
            cgEllipse(X(j), Y(j),4,4)
        end   