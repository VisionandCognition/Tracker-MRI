function RP = cgRandompattern( varargin )

%random pattern generator with fixed pattern for receptive field location
%Call function with :
%RP = cgRandompattern , initializes randompattern 
%RP = cgRandompattern(RF), initialize randompattern with receptive field data
%Receptive field format: RF = [center x, center y, width, height] : all in number of pixels
%RP = cgRandompattern(RF, SQSZ), initialize with RF, and size of squares(Scalar)
%
%RP = cgRandompattern(RP), call with RandomPattern object to reuse the
%receptive field, and square size
%
%C van der Togt, 03-2013
%Vision and Cognition

%rng('shuffle') ; once at the beginning of a session


if nargin > 0
    In = varargin{1};
    if isstruct(In) %is this a random pattern
        RP = In;
        Rnd = logical(round(rand(RP.Lng,1))); %make new random background pattern
        
        if nargin == 3 && strcmp(varargin{2}, 'sprite')
            Id = varargin{3}; %this is the id of the stimulus object
           cgmakesprite(Id, RP.SCSz(1), RP.SCSz(2), 0, 0, 0) %setdimensions and color to black
           cgsetsprite(Id)
           RP = plotRP(RP,Rnd);
           cgsetsprite(0)
           RP.isLoaded = true;
           return
            
        else % just plot
            
            RP = plotRP(RP,Rnd);
        
            if nargin == 2 && strcmp(varargin{2}, 'plot')
            else
                cgflip(0, 0, 0)
            end
            
        return
        end
        
    elseif isnumeric(In) && length(In) == 4 %is this the receptive field location
        RF = In;
        RP.RF = RF;
        
    else
         disp('Error, Not a valid input')
         return 
    end
    
    if nargin > 1
        In = varargin{2};
        if isscalar(In) && In > 0 
            if mod(In, 2) == 0 %number > 0 and dividable by 2
                RP.SqSz = In;
            else
                RP.SqSz = In + 1;
            end
        else
            disp('Error, Square size should be a even number greater than zero')
            return
        end
    else
        RP.SqSz = 6;    %square size, 30px/deg, 5cycles /deg=> 
    end
    
    col = uisetcolor([0.5 0.5 0.5]);
    RP.col = col;
    RP = newRP(RP);
   
else
    RP = struct;  %new curve  
    %RP.RF = [100 100 30 30]; %arbitrary value
    %RP.SqSz = 6;         %square size, 30px/deg, 5cycles /deg=> 
    
    prompt = { 'Enter square size', ...
               'RF center x(px)', 'RF center y(px)', ...
               'RF width(px)',    'RF height(px)'};
           
    dlg_title = 'Input parameters for random square pattern';
    num_lines = 1;
    def = {'6','100','100', '30', '30'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    RF(1) = str2double(answer{2});
    RF(2) = str2double(answer{3});
    RF(3) = str2double(answer{4});
    RF(4) = str2double(answer{5});
    RP.RF = RF;
    RP.SqSz = str2double(answer{1});
    
    col = uisetcolor([0.5 0.5 0.5]);
    RP.col = col;
    RP.isLoaded = false; %true when a sprite is made for this RP
    
    RP = newRP(RP);
end



function RP = plotRP(RP, Rnd)

SCSz = RP.SCSz;
SqSz =  RP.SqSz;
C2 = round(SqSz/2); %half of the square, midpoint

RF = RP.RF;
RP.BM = randsample(3,1); %random selection of one of three possible receptive field bm's.
RfBm = RP.RfBm(:,:, RP.BM);

Wd = RP.Wd;
Hh = RP.Hh; 
Lng = RP.Lng;

col = RP.col;
cgpencol(0.5, 0.5, 0.5)
for i = 1:Lng
    if Rnd(i) == 1;
     cx = (mod(i-1, Wd))*SqSz + C2 - Wd/2*SqSz;
     cy = (mod(floor(i/Wd), Hh))*SqSz + C2 - Hh/2*SqSz;
     cgrect( cx, cy, SqSz, SqSz)
    end
end

for i = 1:size(RfBm,1)
    for j = 1:size(RfBm,2)
        bx = (RF(1) - RF(3)/2)+SqSz*(i-1)+C2;
        by = (RF(2) - RF(4)/2)+SqSz*(j-1)+C2;
        if RfBm(i, j) == 1;
           cgpencol(col(1), col(2), col(3))  
        else
            cgpencol(0, 0, 0)
        end
        cgrect( bx, by, SqSz, SqSz)
    end
end




function RP = newRP( RP)

SqSz =  RP.SqSz;
C2 = round(SqSz/2); %half of the square, midpoint
RF = RP.RF;

gsd = cggetdata('gsd');
SCSz = [gsd.ScreenWidth gsd.ScreenHeight]; %screen size

Wd = round(SCSz(1)./SqSz); %number of horizontal squares
Hh = round(SCSz(2)./SqSz); %number of vertical squares
if mod(Wd,2)~= 0
    Wd = Wd + 1; %should be a multiple of 2
end
if mod(Hh,2) ~= 0
    Hh = Hh + 1;
end

Lng = Wd * Hh;
Rnd = logical(round(rand(Lng,1))); 

RF = floor(RF./SqSz) * SqSz; %position of RF must fit in background

if mod(RF(3)/SqSz,2)~= 0
    RF(3) = RF(3) + SqSz; %should be a multiple of 2*SqSz
end
if mod(RF(4)/SqSz,2)~= 0
    RF(4) = RF(4) + SqSz;
end
Wrf = floor(RF(3)/SqSz);
Hrf = floor(RF(4)/SqSz);
RfBm = zeros( Wrf, Hrf);

cgpencol(0.5, 0.5, 0.5)
for i = 1:Lng
    if Rnd(i)
     x = (mod(i-1, Wd))*SqSz + C2; %index*blockwidth + 1/2 block; block center
     y = (mod(floor(i/Wd), Hh))*SqSz + C2;
     cx = x - Wd/2*SqSz; %with respect to center of pattern
     cy = y - Hh/2*SqSz;  %0,0 in cogent is center of screen!!!!
     
     if abs(cx - RF(1)) < RF(3)/2 && abs(cy - RF(2)) < RF(4)/2
       cgpencol(1, 1, 1)
       
       bx = (cx - C2 - RF(1) + RF(3)/2)/SqSz+1;
       by = (cy - C2 - RF(2) + RF(4)/2)/SqSz+1;
       RfBm(bx, by) = 1;
       
     else
         cgpencol(0.5, 0.5, 0.5)
     end
     cgrect( cx, cy, SqSz, SqSz)
    end
end

cgflip(0, 0, 0)

RfBm = logical(RfBm);
%insure that alternative bitmap in RF has the same number of colored
%squares
RfBm(:,:,2) = logical(reshape(randsample(RfBm(:), Wrf*Hrf), Wrf, Hrf));
RfBm(:,:,3) = logical(reshape(randsample(RfBm(:), Wrf*Hrf), Wrf, Hrf));
%RfBm(:,:,2) = logical(round(rand( RF(3)/SqSz, RF(4)/SqSz )));

RP.Rnd = Rnd;
RP.RF = RF;
RP.SqSz = SqSz;
RP.RfBm = RfBm;
RP.Wd = Wd;
RP.Hh = Hh;
RP.Lng = Lng;
RP.SCSz = SCSz;


