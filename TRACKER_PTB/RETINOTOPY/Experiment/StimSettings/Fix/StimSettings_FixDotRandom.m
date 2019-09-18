%StimSettings
global StimObj

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1
%Stm(1).BackColor = (88/255).*[1 1 1]; % [R G B] 0-1
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm(1).FixDotSize = 0.15;
Stm(1).FixDotSurrSize = 0.75;
Stm(1).FixDotCol = [1 0 0;0 1 0]; %[RGB if not fixating; RGB fixating]

% Fixation position can be toggled with 1-5 keys --------------------------
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-10 -5]; % deg from center (-=left/down)
Stm(1).Position{3} = [+10 -5]; % deg from center (-=left/down)
Stm(1).Position{4} = [-10 +5]; % deg from center (-=left/down)
Stm(1).Position{5} = [+10 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 2; % set zero for manual cycling

% Retinotopic mapping stimulus --------------------------------------------
Stm(1).RandomizeStim=false;
Stm(1).nRepeatsStimSet=1;

Stm(1).RetMap.StimType{1} = 'none'; % face / walker / checkerboard / none
Stm(1).RetMap.StimType{2} = 'circle'; 
% face / walker: circle / wedge
% ret: pRF_8bar / wedge_cw/ccw / ring_con/exp
Stm(1).RetMap.Dir = +1; % +1 = expanding / ccw, -1 = contracting / cw
% only informative for face/walker stimuli
Stm(1).RetMap.TRsPerStep = 1; %s 
Stm(1).RetMap.PreDur_TRs = 5; % volumes
Stm(1).RetMap.PostDur_TRs = 5; % volumes
Stm(1).RetMap.nCycles = 2; % 0=unlimited
Stm(1).RetMap.nSteps = 32; 
% (32 for KUL face/walkers; multiple of 8 for 8bar)
Stm(1).RetMap.nBlanks_each_nSteps = [0 0]; % if either is zero, it won't work

% Logfolder
Stm(1).LogFolder = fullfile('Retinotopy','Fix');

%% 
%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;