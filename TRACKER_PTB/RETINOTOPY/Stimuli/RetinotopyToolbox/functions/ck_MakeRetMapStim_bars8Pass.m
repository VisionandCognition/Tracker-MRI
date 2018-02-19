function [stimulus] = ck_MakeRetMapStim_bars8Pass(params, Stm, STIMNR)
% makeRetinotopyStimulus - make various retinotopy stimuli
% original: makeRetinotopyStimulus_bars8Pass(params)
%
% stimulus = ck_MakeRetMapStim_bars8Pass(params)
%
% based on Harvey/Dumoulin code
% adapted for Tracker@NIN, C.Klink, Feb 2016

global Par      %global parameters

%% create a stimulus ======================================================
barPassTime=Stm(STIMNR).RetMap.nSteps*Stm(STIMNR).RetMap.TRsPerStep*Par.TR;
numBarImages=params.numImages;

outerRad = params.radius;
innerRad = params.innerRad;
wedgeWidth = params.wedgeWidth;
ringWidth = params.ringWidth;

halfNumImages = Stm(STIMNR).RetMap.nSteps/2;
numMotSteps = params.temporal.motionSteps;
numSubRings = params.numSubRings;
numSubWedges = params.numSubWedges;

%%% Set check colormap indices %%%
bk = Stm(STIMNR).BackColor(1)*Par.ScrWhite;
minCmapVal = Par.ScrBlack; %min([params.display.stimRgbRange]);
maxCmapVal = Par.ScrWhite; %max([params.display.stimRgbRange]);

%%% Initialize image template %%%
m=round(outerRad*Par.PixPerDeg*2);
n=m;

[x,y]=meshgrid(linspace(-outerRad,outerRad,n),linspace(outerRad,-outerRad,m));

r = sqrt (x.^2  + y.^2);
theta = atan2 (y, x);					% atan2 returns values between -pi and pi
theta(theta<0) = theta(theta<0)+2*pi;	% correct range to be between 0 and 2*pi


% loop over different orientations and make checkerboard
% first define which orientations
orientdeg = (0:45:360);
orientations = orientdeg(1:end-1)./360*(2*pi); % degrees -> rad
orient_order = [3 2 5 4 7 6 1 8]; %[3 2 5 4 7 6 1 8];
if Stm(STIMNR).RetMap.Dir>0
    orientdeg = orientdeg(orient_order);
else
    orientdeg = fliplr(orientdeg);
end
remake_xy    = zeros(1,numBarImages)-1;
warning off
remake_xy(1:length(remake_xy)/length(orientations):length(remake_xy)) = orientations;
warning on
original_x   = x;
original_y   = y;

% step size of the bar
step_nx      = barPassTime./Par.TR/8;
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);
softmask = ones(m);

% Loop that creates the final images
imgcell=cell(1,halfNumImages/length(orientations));
for imgNum=1:halfNumImages
    imgcell{imgNum}=zeros(m,n,params.temporal.motionSteps,'uint8');
    if remake_xy(imgNum) >=0,
        x = original_x .* cos(remake_xy(imgNum)) - original_y .* sin(remake_xy(imgNum));
        y = original_x .* sin(remake_xy(imgNum)) + original_y .* cos(remake_xy(imgNum));
        
        % Calculate checkerboard.
        % Wedges alternating between -1 and 1 within stimulus window.
        % The computational contortions are to avoid sign=0 for sin zero-crossings
        
        wedges    = sign(round((cos((x+step_startx)*numSubRings*(2*pi/ringWidth)))./2+.5).*2-1);
        posWedges = find(wedges== 1);
        negWedges = find(wedges==-1);
        rings     = zeros(size(wedges));
        
        checks    = zeros(size(rings,1),size(rings,2),params.temporal.motionSteps);
        for ii=1:numMotSteps,
            tmprings1 = sign(2*round((cos(y*numSubRings*(2*pi/ringWidth)+(ii-1)/numMotSteps*2*pi)+1)/2)-1);
            tmprings2 = sign(2*round((cos(y*numSubRings*(2*pi/ringWidth)-(ii-1)/numMotSteps*2*pi)+1)/2)-1);
            rings(posWedges) = tmprings1(posWedges);
            rings(negWedges) = tmprings2(negWedges);
            
            checks(:,:,ii)=minCmapVal+ceil((maxCmapVal-minCmapVal) * (wedges.*rings+1)./2);
        end;
        
        % reset starting point
        loX = step_startx - step_x;
    end;
    
    switch params.type;
        case 'bar'
            loEcc = innerRad;
            hiEcc = outerRad;
            loX   = loX + step_x;
            hiX   = loX + ringWidth;
        otherwise,
            error('Unknown stimulus type!');
            
    end
    % This isn't as bad as it looks
    % Can fiddle with this to clip the edges of an expanding ring - want the ring to completely
    % disappear from view before it re-appears again in the middle.
    
    % Can we do this just be removing the second | from the window
    % expression? so...
    window = ( (x>=loX & x<=hiX) & r<outerRad);
    
    % yet another loop to be able to move the checks...
    tmpvar = zeros(m,n);
    tmpvar(window) = 1;
    tmpvar = repmat(tmpvar,[1 1 numMotSteps]);
    window = tmpvar == 1;
    img         = bk*ones(size(checks));
    imgb=img;
    img(window) = checks(window);
    
    %images(:,:,(imgNum-1).*numMotSteps+1:imgNum.*numMotSteps) = uint8(img);
    imgcell{imgNum}(:,:,1:numMotSteps)= uint8(img);
end

%% make stimulus structure for output =====================================
imgperorient = length(imgcell)/4;

% pick
stimulus(STIMNR).img = imgcell(1,1:imgperorient);

% enter blank positions into stimulus structure
% create position map and put blank steps in place
stepnr=1; posmap=[];
for i=1:length(orientations)%length(stimulus)
    for j=1:length(stimulus(1).img)
        posmap=[posmap; i stepnr];
        stepnr=stepnr+1;
    end
end
stimulus(STIMNR).posmap=posmap;
stimulus(STIMNR).orient=orientdeg;

% insert blanks where necessary
if Stm(STIMNR).RetMap.nBlanks_after_cardinals > 0
    posmap2=[];
    for i=1:size(posmap,1)-1
        if mod(posmap(i,1),2) && ~mod(posmap(i+1,1),2)
            posmap2=[posmap2; ...
                posmap(i,:); ...
                zeros(Stm(STIMNR).RetMap.nBlanks_after_cardinals,2)];
        else
            posmap2=[posmap2; posmap(i,:)];
        end
    end
    posmap2=[posmap2; posmap(end,:)];
    stimulus(STIMNR).posmap=posmap2;
end