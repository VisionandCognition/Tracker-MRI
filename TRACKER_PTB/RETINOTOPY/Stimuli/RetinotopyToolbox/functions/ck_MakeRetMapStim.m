function stimulus = ck_MakeRetMapStim(params, Stm, STIMNR)
% makeRetinotopyStimulus(params)
% makeRetinotopyStimulus - make various retinotopy stimuli
%
% based on Harvey/Dumoulin code
% adapted for Tracker@NIN, C.Klink, Feb 2016

global Par      %global parameters

%% create a stimulus ======================================================
outerRad = params.radius;
innerRad = params.innerRad;
wedgeWidth = params.wedgeWidth;
ringWidth = params.ringWidth;

numImages = Stm(STIMNR).RetMap.nSteps;
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

mask = ck_makecircle(m*24/28,m);

% r = eccentricity; theta = polar angle
r = sqrt (x.^2  + y.^2);
theta = atan2 (y, x);					% atan2 returns values between -pi and pi
theta(theta<0) = theta(theta<0)+2*pi;	% correct range to be between 0 and 2*pi

% Calculate checkerboard.
% Wedges alternating between -1 and 1 within stimulus window.
% The computational contortions are to avoid sign=0 for sin zero-crossings
wedges = sign(2*round((sin(theta*numSubWedges*(2*pi/wedgeWidth))+1)/2)-1);
posWedges = find(wedges==1);
negWedges = find(wedges==-1);

rings = wedges.*0;
rings = sign(2*round((sin(r*numSubRings*(2*pi/ringWidth))+1)/2)-1);

checks   = zeros(size(rings,1),size(rings,2),params.temporal.motionSteps);
for ii=1:numMotSteps,
    tmprings1 = sign(2*round((sin(r*numSubRings*(2*pi/ringWidth)+(ii-1)/numMotSteps*2*pi)+1)/2)-1);
    tmprings2 = sign(2*round((sin(r*numSubRings*(2*pi/ringWidth)-(ii-1)/numMotSteps*2*pi)+1)/2)-1);
    rings(posWedges)=tmprings1(posWedges);
    rings(negWedges)=tmprings2(negWedges);
    
    checks(:,:,ii)=minCmapVal+ceil((maxCmapVal-minCmapVal) * (wedges.*rings+1)./2);
end;

% Loop that creates the final images
% fprintf('[%s]:Creating %d images:',mfilename,numImages);
imgcell=cell(1,params.numImages);
for imgNum=1:params.numImages
    imgcell{imgNum}=zeros(m,n,params.temporal.motionSteps,'uint8');
    switch params.type;
        case 'wedge',
            loAngle = 2*pi*((imgNum-1)/numImages);
            hiAngle = loAngle + wedgeWidth;
            %                 end;
            loEcc = innerRad;
            hiEcc = outerRad;
        case 'ring',
            loAngle = 0;
            hiAngle = 2*pi;
            loEcc = outerRad * (imgNum-1)/numImages;
            hiEcc = loEcc+ringWidth;
        case 'center-surround',
            loAngle = 0;
            hiAngle = 2*pi;
            if mod(imgNum,2)
                loEcc = params.centerInnerRad;
                hiEcc = params.centerOuterRad;
            else
                loEcc = params.surroundInnerRad;
                hiEcc = params.surroundOuterRad;
            end
            hiEcc = hiEcc.*2;
        otherwise,
            error('Unknown stimulus type!');
            
    end
    % This isn't as bad as it looks
    % Can fiddle with this to clip the edges of an expanding ring - want the ring to completely
    % disappear from view before it re-appears again in the middle.
    
    % Can we do this just be removing the second | from the window expression? so...
    window = ( ((theta>=loAngle & theta<hiAngle) | ...
        (hiAngle>2*pi & theta<mod(hiAngle,2*pi))) & ...
        ((r>=loEcc & r<=hiEcc)) & ...
        r<outerRad) ;

    for ii=1:numMotSteps,
        img = bk*ones(m,n);
        tmpvar = checks(:,:,ii);
        img(window) = tmpvar(window);
        images(:,:,imgNum*numMotSteps-numMotSteps+ii) = uint8(img);
        imgcell{imgNum}(:,:,ii) = uint8(img);
    end;
end

%% make stimulus structure for output =====================================
%stimulus = createStimulusStruct(images,cmap,sequence,[],timing,fixSeq);
stimulus(1).img=imgcell;

% create position map and put blank steps in place
stepnr=1; posmap=[];
for i=1:length(stimulus)
    for j=1:length(stimulus(i).img)
        posmap=[posmap; i stepnr];
        stepnr=stepnr+1;
    end
end
% change the position map for contraction or cw rotation
if strcmp(Stm(STIMNR).Descript,'wedge_cw')
    posmap = [ posmap(1,:); flipud(posmap(2:end,:))];
elseif strcmp(Stm(STIMNR).Descript,'ring_con')
    posmap = flipud(posmap);
end
stimulus(STIMNR).posmap=posmap;

% insert blanks where necessary
if Stm(STIMNR).RetMap.nBlanks_each_nSteps(1)~=0 && ...
        Stm(STIMNR).RetMap.nBlanks_each_nSteps(1)~=0
    posmap2=[];
    stepsdone=0; cons_steps=0; blanksdone = 0;
    while stepsdone < size(posmap,1)
        if cons_steps < Stm(STIMNR).RetMap.nBlanks_each_nSteps(2) && ...
                stepsdone < size(posmap,1)
            posmap2=[posmap2; posmap(stepsdone+1,:)];
            stepsdone = stepsdone+1;
            cons_steps = cons_steps+1;
        elseif cons_steps == Stm(STIMNR).RetMap.nBlanks_each_nSteps(2) && ...
                blanksdone < Stm(STIMNR).RetMap.nBlanks_each_nSteps(1)
            posmap2=[posmap2; 0 0];
            blanksdone = blanksdone+1;
        elseif cons_steps == Stm(STIMNR).RetMap.nBlanks_each_nSteps(2) && ...
                blanksdone == Stm(STIMNR).RetMap.nBlanks_each_nSteps(1)
            cons_steps = 0;
            blanksdone = 0;
        end
    end
    stimulus(STIMNR).posmap=posmap2;
end