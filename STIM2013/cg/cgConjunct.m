function [Stm, Obj, IDs] = cgConjunct


global Par


%my stimulus
Stm(1).Name = 'Conjunction';
Stm(1).Id = 1;
Stm(1).Fix = 1;
Stm(1).Targ = 2;
Stm(1).Talt = {[]};
Stm(1).Event = { 1 , [], 3, [], [] };

IDs = [1 2 3];

%my fixation dot
dot.cx = 0;
dot.cy = 0;
dot.w = 20;
dot.h = 20;
dot.color = [1 1 1];
dot.fill = 'f';
fixobj.Type = 'Dot';
fixobj.Id = 1;
fixobj.Data = dot;
Obj(1) = fixobj;

%the target object doesn't get displayed, it's just to define it's location
%these are dummy values required for a dot object
dot.w = 1;
dot.h = 1;
dot.fill = '';
dot.color = [1 1 1];
%we still need to define its location below

target.Type = 'Dot';
target.Id = 2;  


%the object (a sprite) to display
Obj(3).Type = 'Sprite';
Obj(3).Id = 3;
Obj(3).Data = []; %don't need to put anything here

%cgfreesprite(3)
cgmakesprite(3, 2*Par.HW, 2*Par.HH, 0, 0, 0);

%some parameters
ZSspot = 80; %size of dots and squares
Space = 150; %distance between objects
Jitter = 70; % less than 70 = Space - ZSspot
Color1 = [0.7, 0.6, 0.0];
Color2 = [0.0, 0.6, 0.7];

D2Sz = round(Space/2);
Hnm = round((Par.HW-D2Sz)./Space) * 2 + 1;
Vnm = round((Par.HH-D2Sz)./Space) * 2 + 1;
Midx = floor(Hnm/2);
Midy = floor(Vnm/2);

Tnm = Hnm * Vnm;
st = ceil(rand*(Tnm-1));
OFFx = D2Sz - Space * Hnm/2;
OFFy = D2Sz - Space * Vnm/2;

%do the drawing on the sprite
CNT = 1;
cgsetsprite(3)
for i = 0:Hnm-1
    for j = 0:Vnm-1  
         %center free of stimuli
        if ~(i == Midx && j == Midy)
            Wide = OFFx + Space * i + rand*Jitter - Jitter/2;
            High = OFFy + Space * j + rand*Jitter - Jitter/2;
           
            if rand < 0.5
                if CNT == st
                    cgpencol(Color1(1), Color1(2), Color1(3))
                    dot.cx = Wide;
                    dot.cy = High;

                else
                   cgpencol(Color2(1), Color2(2), Color2(3))
                end
                cgrect(Wide,High,ZSspot,ZSspot)

            else
                if CNT == st
                    cgpencol(Color2(1), Color2(2), Color2(3))
                    dot.cx = Wide;
                    dot.cy = High;

                else
                   cgpencol(Color1(1), Color1(2), Color1(3))
                end
                cgellipse(Wide,High,ZSspot,ZSspot, 'f')
            end
            CNT = CNT + 1;
        end
    end
end

target.Data = dot;
Obj(2) = target;

cgsetsprite(0)
%cgdrawsprite(3,0,0)
%cgflip(0,0,0)

