function Bitmap = cgbitmap( varargin ) %bitmap is a structure, mode is what to do

% A = cgFlip('v');
% if A == -2
%     disp('Open a Cogent window before using this function!!!');
%     
%     return
% end
mode = 0;
Bitmap = [];
Id = [];

if nargin == 0
    disp('Error you must provide a bitmap data, at least a file name')
    return
    
elseif nargin > 0
    Bitmap = varargin{1};
    if nargin > 1
        mode = varargin{2};
        if nargin > 2
            Id = varargin{3};
        end
    end
end

if mode == 'P' && Bitmap.isLoaded
       % cgblitsprite(Bitmap.Id, 0, 0, Bitmap.w, Bitmap.h, Bitmap.cx, Bitmap.cy)
        cgdrawsprite(Bitmap.Id, Bitmap.cx, Bitmap.cy)
        return
end

if ~isempty(Bitmap) && ~isempty(Id)
    if mode == 'L' || mode == 'D'
        cgloadbmp(Id, Bitmap.Filename )
        if ~isempty(Bitmap.Tcol) && ~isempty(regexp(Bitmap.Tcol, '[nrgybmcw]', 'once'))
            cgtrncol(Id, Bitmap.Tcol)
        end
        Bitmap.isLoaded = true;
        Bitmap.Id = Id;
        
        if mode == 'D'
%             cgblitsprite(Id, 0, 0, Bitmap.w, Bitmap.h, Bitmap.cx, Bitmap.cy)
%             cgflip
%             cgblitsprite(Id, 0, 0, Bitmap.w, Bitmap.h, Bitmap.cx, Bitmap.cy)
            cgdrawsprite(Id, Bitmap.cx, Bitmap.cy)
            cgflip
            cgdrawsprite(Id, Bitmap.cx, Bitmap.cy)
            %cgdrawsprite(Id, cx, cy)
        end
    
    elseif mode == 'E'

        temp = bmpui(Bitmap);
        if ~isempty(temp)
            Bitmap = temp;
        end
                
    end
end