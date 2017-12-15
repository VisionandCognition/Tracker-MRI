%StimSettings
global StimObj

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
Stm(1).BackColor = [.75 .75 .75]; % [R G B] 0-1
%Stm(1).BackColor = (88/255).*[1 1 1]; % [R G B] 0-1
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm(1).FixDotSize = 0.15;
Stm(1).FixDotSurrSize = 0.75;
Stm(1).FixDotCol = [1 0 0;1 0 0]; %[RGB if not fixating; RGB fixating]
% fixation color is overwritten by parsettings!

% Fixation position can be toggled with 1-5 keys --------------------------
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-4 0]; % deg from center (-=left/down)
Stm(1).Position{3} = [0 -4]; % deg from center (-=left/down)
Stm(1).Position{4} = [4 0]; % deg from center (-=left/down)
Stm(1).Position{5} = [0 4]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 0; % set zero for manual cycling

% Retinotopic mapping stimulus --------------------------------------------
Stm(1).RandomizeStim=false;
Stm(1).nRepeatsStimSet=1;

Stm(1).RetMap.StimType{1} = 'ret'; % face / walker / checkerboard
Stm(1).RetMap.StimType{2} = 'pRF_8bar'; % circle / wedge
% face / walker: circle / wedge
% ret: pRF_8bar / wedge_cw/ccw / ring_con/exp
Stm(1).RetMap.Dir = 1; % +1 = expanding / ccw, -1 = contracting / cw
% only informative for face/walker stimuli
Stm(1).RetMap.TRsPerStep = 1; %s
Stm(1).RetMap.PreDur_TRs = 5; % volumes
Stm(1).RetMap.PostDur_TRs = 5; % volumes
Stm(1).RetMap.nCycles = 1; % 0=unlimited

% This only applies to newly created stim =================================
Stm(1).RetMap.StimSize = 16; % [15] degrees (square) >> diameter
% Maximum size is screen height, will be corrected if it exceeds!
Stm(1).RetMap.nSteps = 8*20; %(8 directions * number of steps per sweep)
% (32 for KUL face/walkers; multiple of 8 for 8bar)
Stm(1).RetMap.nBlanks_after_cardinals = 15; % bars
Stm(1).RetMap.nBlanks_each_nSteps = [0 0]; % wedge/rings
Stm(1).RetMap.MotionSteps = 15; % number of checker motion steps
Stm(1).RetMap.fps = 15; % speed of checker motion
Stm(1).RetMap.WedgeDeg = 45; % angular coverage of wedge
Stm(1).RetMap.SubWedgeDeg = 15; % angular coverage of checkers in wedge
Stm(1).RetMap.RingDeg = Stm(1).RetMap.StimSize/8; % width of stim ring
Stm(1).RetMap.SubRingDeg = Stm(1).RetMap.RingDeg/5; % width of checker ring
Stm(1).RetMap.BarWidth = Stm(1).RetMap.StimSize/8; % bar width in deg
Stm(1).RetMap.chksize = Stm(1).RetMap.BarWidth/4; % bar checker size in deg
% =========================================================================

Stm(1).RetMap.LoadFromFile = true;
% NB! loading a stimulus overwrites all settings with the ones saved!
Stm(1).RetMap.SaveToFile = false;
Stm(1).RetMap.FileName = 'pRF_8bars_3T_TR2500ms.mat';

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;