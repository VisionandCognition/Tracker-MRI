<<<<<<< Updated upstream
function stimulus = ck_ret(Stm,STIMNR)
% ck_ret - toolbox for retinotopic mapping stimuli
% based on Harvey/Dumoulin code
% adapted for Tracker@NIN, C.Klink, Feb 2016

global Par      %global parameters

%% get parameters =========================================================
% change this to use a settings file
switch Stm(STIMNR).Descript
    case 'pRF_8bar'
        params.experiment = 'pRF_8bar';
    case 'wedge_cw'
        params.experiment = 'wedge';
    case 'wedge_ccw'
        params.experiment = 'wedge';
    case 'ring_con'
        params.experiment = 'ring';
    case 'ring_exp'
        params.experiment = 'ring';
end

params.period = Stm(STIMNR).RetMap.nSteps*...
    Stm(STIMNR).RetMap.TRsPerStep*Par.TR;
params.numCycles = Stm(STIMNR).RetMap.nCycles; % defined elsewhere
params.tr = Par.TR; % define elsewhere

params.stimSize = Stm(STIMNR).RetMap.StimSize; % defined elsewhere
% Max size is screen size
if Stm(STIMNR).RetMap.StimSize > Par.wrect(4)/Par.PixPerDeg;
    params.stimSize = (Par.wrect(4)/Par.PixPerDeg);
else
    params.stimSize = Stm(STIMNR).RetMap.StimSize;
end
Stm(STIMNR).RetMap.StimSize_Corrected = params.stimSize;
% stimulus size in degrees (max screen-height)

% now set rest of the params
params.numPixels = [Par.HW*2 Par.HH*2];
params.dimensions = [Par.ScreenWidthD2 Par.ScreenHeightD2];
params.distance = Par.DistanceToScreen;

% use the SetRetMapParams functions to set more
params = ck_SetRetMapParams(params.experiment, params, Stm, STIMNR);

%% make stimulus ==========================================================
switch params.experiment
    case {'pRF_8bar'},
        stimulus= ck_MakeRetMapStim_bars8Pass(params, Stm, STIMNR);
    otherwise
        stimulus = ck_MakeRetMapStim(params, Stm, STIMNR);
=======
function stimulus = ck_ret(Stm,STIMNR)
% ck_ret - toolbox for retinotopic mapping stimuli
% based on Harvey/Dumoulin code
% adapted for Tracker@NIN, C.Klink, Feb 2016

global Par      %global parameters

%% get parameters =========================================================
% change this to use a settings file
switch Stm(STIMNR).Descript
    case 'pRF_8bar'
        params.experiment = 'pRF_8bar';
    case 'wedge_cw'
        params.experiment = 'wedge';
    case 'wedge_ccw'
        params.experiment = 'wedge';
    case 'ring_con'
        params.experiment = 'ring';
    case 'ring_exp'
        params.experiment = 'ring';
end

params.period = Stm(STIMNR).RetMap.nSteps*...
    Stm(STIMNR).RetMap.TRsPerStep*Par.TR;
params.numCycles = Stm(STIMNR).RetMap.nCycles; % defined elsewhere
params.tr = Par.TR; % define elsewhere

params.stimSize = Stm(STIMNR).RetMap.StimSize; % defined elsewhere
% Max size is screen size
if Stm(STIMNR).RetMap.StimSize > Par.wrect(4)/Par.PixPerDeg;
    params.stimSize = (Par.wrect(4)/Par.PixPerDeg);
else
    params.stimSize = Stm(STIMNR).RetMap.StimSize;
end
Stm(STIMNR).RetMap.StimSize_Corrected = params.stimSize;
% stimulus size in degrees (max screen-height)

% now set rest of the params
params.numPixels = [Par.HW*2 Par.HH*2];
params.dimensions = [Par.ScreenWidthD2 Par.ScreenHeightD2];
params.distance = Par.DistanceToScreen;

% use the SetRetMapParams functions to set more
params = ck_SetRetMapParams(params.experiment, params, Stm, STIMNR);

%% make stimulus ==========================================================
switch params.experiment
    case {'pRF_8bar'},
        stimulus= ck_MakeRetMapStim_bars8Pass(params, Stm, STIMNR);
    otherwise
        stimulus = ck_MakeRetMapStim(params, Stm, STIMNR);
>>>>>>> Stashed changes
end