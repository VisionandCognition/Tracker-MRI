%StimSettings
global StimObj

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
%Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1
Stm(1).BackColor = [.25 .25 .25]; % [R G B] 0-1
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm(1).FixDotSize = 0.15;
Stm(1).FixDotSurrSize = 0.75;
Stm(1).FixDotCol = [1 0 0;1 0 0]; %[RGB if not fixating; RGB fixating]

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

Stm(1).RetMap.StimType{1} = 'movie'; % ignores many of the settings due to irrelevance
Stm(1).RetMap.StimType{2} = 'TeaParty'; % circle / wedge
% face / walker: circle / wedge
% ret: pRF_8bar / wedge_cw/ccw / ring_con/exp
Stm(1).RetMap.Dir = -1; % +1 = expanding / ccw, -1 = contracting / cw
% only informative for face/walker stimuli
Stm(1).RetMap.TRsPerStep = 228; %s 
Stm(1).RetMap.PreDur_TRs = 5; % volumes
Stm(1).RetMap.PostDur_TRs = 5; % volumes
Stm(1).RetMap.nCycles = 1; % 0=unlimited
Stm(1).RetMap.nSteps = 1; 
% (32 for KUL face/walkers; multiple of 8 for 8bar)
Stm(1).RetMap.nBlanks_each_nSteps = [0 0]; % if either is zero, it won't work

Stm(1).RetMap.LoadFromFile = false;
% NB! loading a stimulus overwrites all settings with the ones saved!
Stm(1).RetMap.SaveToFile = false;
Stm(1).RetMap.FileName = 'TeaParty.mp4';
Stm(1).RetMap.moviefps = 30; % framerate of moviefile
Stm(1).RetMap.movierate = 0.5; % speed of playing
Stm(1).RetMap.moviedur = 185; % sec
Stm(1).RetMap.PlaySize = [640*(1080/480) 1080]; % max height & keep ratio

% Logfolder
Stm(1).LogFolder = fullfile('Retinotopy','TeaParty');

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;