function tex = cgTexture(varargin) 
% tex = cgTexture(varargin)
% function cgDrawTexture                 make a new texture
% function cgDrawTexture(tex, mode)      edit a texture (mode = 'E')
% function cgDrawTexture(tex, Id, mode)  edit, load , display texture
  
%
% tex is a structure with the entries
%    tex.barWidth = 4;        width of bars (in pixels)
%    tex.barLength = 18;      length of bars (in pixels)
%    tex.spacex = 12;         spacing between bars (in pixels, hor)
%    tex.spacey = 12;         spacing between bars (in pixels, ver)
%    tex.sizex = 1024;        size of screen (do not alter)
%    tex.sizey = 768;         size of screen (do not alter)
%    tex.posNoise = 8;        position noise (in pixels)
%    tex.barOrientation = 45; orientation 
%    tex.filename

tex = [];
Id = [];
mode = 0;

if nargin > 0 && nargin < 2
    display('Error see usage: '), help cgTexture
    return
elseif nargin  == 2
    tex = varargin{1};
    mode = varargin{2};   
    
elseif nargin  == 3
    tex = varargin{1};
    mode = varargin{2};
    Id = varargin{3};
end

if   ~isempty(tex) && ~isempty(Id)
    
    if   mode == 'P' && tex.isLoaded
        cgblitsprite(Id, tex.cx, tex.cy, tex.w, tex.h, tex.cx, tex.cy)
        return

    elseif  mode == 'L'  
        cgloadbmp(Id, [tex.Filename '.BMP'])
        tex.isLoaded = true;
        return

    elseif mode == 'D'  
        cgloadbmp(Id, [tex.Filename '.BMP'])
        tex.isLoaded = true;

        cgblitsprite(Id, tex.cx, tex.cy, tex.w, tex.h, tex.cx, tex.cy)
        cgflip
        %cgDrawSprite(Id, tex.SPosx, tex.SPosy)
        cgblitsprite(Id, tex.cx, tex.cy, tex.w, tex.h, tex.cx, tex.cy)
        return
        
    end

elseif mode == 'E'
    temp = texui(tex);
    if ~isempty(temp)
        tex = temp;
        tex.isLoaded = false;
    end
    
else    %if mode == 0 %new
    
    tex = texui;
    if ~isempty(tex)
        tex = Rotate(tex);
        DrawPattern(tex);
        cgscrdmp(tex.Filename)
        tex.isLoaded = false;
    end
end



%------------------------------------------------------------------------
function tex = Rotate(tex)
%
%
%

barOrientation = (tex.BarOrientation / 180) * pi;

barCorners(1).x = (0 - (tex.BarWidth/2));  
barCorners(2).x = (0 - (tex.BarWidth/2));
barCorners(3).x = (0 + (tex.BarWidth/2));
barCorners(4).x = (0 + (tex.BarWidth/2));

barCorners(1).y = (0 + (tex.BarLength/2));
barCorners(2).y = (0 - (tex.BarLength/2));
barCorners(3).y = (0 - (tex.BarLength/2));
barCorners(4).y = (0 + (tex.BarLength/2));

for cPoints = 1:4
    tex.BarRotCorners(cPoints).x = (0 + (((barCorners(cPoints).x * cos(barOrientation)) - (barCorners(cPoints).y * sin(barOrientation)))));
    tex.BarRotCorners(cPoints).y = (0 - (((barCorners(cPoints).x * sin(barOrientation)) + (barCorners(cPoints).y * cos(barOrientation)))));
end

%-------------------------------------------------------------------------
function DrawPattern(tex)
%
%
%
gsd = cggetdata('gsd');
tex.w = gsd.ScreenWidth;
tex.h = gsd.ScreenHeight;

BG = tex.BGcolor;
cgpencol(BG(1), BG(2), BG(3))
cgrect
FG = tex.FGcolor;
cgpencol(FG(1), FG(2), FG(3))

% reset the clock
rand('state',sum(100*clock));
i=1;
% draw the line elements
while i< tex.w
    j = 1;
    while j< tex.h
        x = i - tex.w/2;
        y = j - tex.h/2;
        x = x + tex.PosNoise * mod(rand(1),1)-0.5;
        y = y + tex.PosNoise * mod(rand(1),1)-0.5;
        tex.BarOrientation = Perlin(x, y, 300) * 180;
        tex = Rotate(tex);
        if tex.OrNoise == 1 && rand < 0.5
            coordsX(1) = x - tex.BarRotCorners(1).y;
            coordsY(1) = y + tex.BarRotCorners(1).x;
            coordsX(2) = x - tex.BarRotCorners(2).y;
            coordsY(2) = y + tex.BarRotCorners(2).x;
            coordsX(3) = x - tex.BarRotCorners(3).y;
            coordsY(3) = y + tex.BarRotCorners(3).x;
            coordsX(4) = x - tex.BarRotCorners(4).y;
            coordsY(4) = y + tex.BarRotCorners(4).x;
        else
            coordsX(1) = x + tex.BarRotCorners(1).x;
            coordsY(1) = y + tex.BarRotCorners(1).y;
            coordsX(2) = x + tex.BarRotCorners(2).x;
            coordsY(2) = y + tex.BarRotCorners(2).y;
            coordsX(3) = x + tex.BarRotCorners(3).x;
            coordsY(3) = y + tex.BarRotCorners(3).y;
            coordsX(4) = x + tex.BarRotCorners(4).x;
            coordsY(4) = y + tex.BarRotCorners(4).y;            
            
        end
        
        cgpolygon(coordsX,coordsY)
        j = j + tex.Spacey;
    end
    i = i + tex.Spacex;
end

cgflip(0,0,0)