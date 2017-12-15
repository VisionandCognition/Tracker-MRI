function params = ck_SetRetMapParams(expName, params, Stm, STIMNR)
% set parameters for different retinotopy stimuli
%
% original: params = setRetinotopyParams([expName], [params])
% Sets parameter values for the specified expName.
%
% params is a struct with at least the following fields:
%  period, numCycles, tr, interleaves, framePeriod, startScan, prescanDuration
%
% Returns the parameter values in the struct params.
% If called with no arguments, params will be a cell array listing
% all the experiment names that it is configured to do.
%
% based on Harvey/Dumoulin code
% adapted C.Klink, Feb 2016

%% set some more parameters ===============================================
params.temporal.motionSteps = Stm(STIMNR).RetMap.MotionSteps;
params.radius = params.stimSize/2; 

% Wedge parameters
params.innerRad = 0;		% Non-zero for annular wedge condition (deg)
%params.wedgeDeg = 90;		% Wedge polar angle (deg)
params.subWedgeDeg = Stm(1).RetMap.SubWedgeDeg;	% Sub wedge polar angle (deg)

% Ring parameter - 8 for a radius=16 stim gives a 180 degree duty cycle
%params.ringDeg = params.radius/2;			% Ring radius/width (deg)

% Wedge and ring parameters
params.subRingDeg = Stm(STIMNR).RetMap.SubRingDeg;	% 1/2 radial spatial freq (deg)

params.numImages = Stm(STIMNR).RetMap.nSteps;
%params.period/params.framePeriod;  % Number of samples of the image (i.e. per cycle)
%params.duration = params.period/params.numImages;

switch expName
    case 'wedge',
        params.type = 'wedge';		% Set to 'wedge' or 'ring'
        params.ringDeg = Stm(1).RetMap.RingDeg;
        params.wedgeDeg = Stm(STIMNR).RetMap.WedgeDeg;
        %params.seqDirection = 0;
        params.numSubRings = (params.ringDeg)/(2*params.subRingDeg);
    case 'ring',
        params.type = 'ring';
        params.ringDeg = Stm(1).RetMap.RingDeg;
        params.wedgeDeg = Stm(STIMNR).RetMap.WedgeDeg;
        %params.seqDirection = 0;
        params.numSubRings = (params.ringDeg)/(2*params.subRingDeg);
    case {'pRF_8bar'},
        params.type = 'bar';
        params.ringDeg = Stm(STIMNR).RetMap.BarWidth;%params.radius./4;
        params.wedgeDeg = Stm(STIMNR).RetMap.WedgeDeg;
        %determines barwidth
        %params.seqDirection = 0;
        % params.insertBlanks.do = 1;
        params.numSubRings = Stm(STIMNR).RetMap.BarWidth/(Stm(STIMNR).RetMap.chksize*2);
        %(params.radius-params.innerRad)/(params.radius);
        % determines number of checks in bar width
    otherwise
        error('Unknown expName!');
end

%% Calculations (not to be updated by user)	===============================
params.ringWidth=params.ringDeg;

% Polar angle of wedge in radians
params.wedgeWidth = params.wedgeDeg * (pi/180);

% Number of rings in each wedge
% params.numSubRings = (params.radius-params.innerRad)/(2*params.subRingDeg);
% params.numSubRings = (params.radius-params.innerRad)/(params.radius);
% params.numSubRings = (params.radius)/(2*params.subRingDeg);

% Number of wedges in each ring
params.numSubWedges = params.wedgeDeg/(2*params.subWedgeDeg);