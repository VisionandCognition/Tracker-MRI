%StimSettings
global StimObj

% NB! THIS IS BASED ON A STRUCTURE WITH
% TR 3s
% 5 volumes pre-stim (15s)
% 5 volumes post-stim (15s)
% 20 cycles with 5 volumes ON, 5 volumes OFF (20*30s)

% Total minimum volumes required: 210 (630s)

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime = false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1
%Stm(1).BackColor = (88/255).*[1 1 1]; % [R G B] 0-1
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm(1).FixDotSize = 0.15;
Stm(1).FixDotSurrSize = 0.75;
Stm(1).FixDotCol = [1 0 0 ; 1 0 0]; %[RGB if not fixating; RGB fixating]

% Indicators for which hand to use
Stm(1).SideIndicatorColor = [0 .7 0; .95 0 .25]; % colors for the left and right target

% Fixation position can be toggled with 1-5 keys --------------------------
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-10 -5]; % deg from center (-=left/down)
Stm(1).Position{3} = [+10 -5]; % deg from center (-=left/down)
Stm(1).Position{4} = [-10 +5]; % deg from center (-=left/down)
Stm(1).Position{5} = [+10 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 0; % set zero for manual cycling

% Retinotopic mapping stimulus --------------------------------------------
Stm(1).RandomizeStim = true;
Stm(1).nRepeatsStimSet = 20;

% Stm(1).RetMap.StimType{1} = 'face'; % face / walker / checkerboard / none
% Stm(1).RetMap.StimType{2} = 'circle'; % circle / wedge
% Stm(1).RetMap.Dir = +1; % +1 = expanding / ccw, -1 = contracting / cw
% Stm(1).RetMap.TRsPerStep = 1; %s (movieclips are 2 s, there are 32 clips)
% Stm(1).RetMap.nCycles = 0; % 0=unlimited
% Stm(1).RetMap.PreDur_TRs = 5; % volumes
% Stm(1).RetMap.PostDur_TRs = 5; % volumes

% Checkerboard stimuli ----------------------------------------------------
Stm(1).RetMap.PreDur_TRs = 5; % TR's NB! With a TR of 3 sec, this is 15 s
Stm(1).RetMap.PostDur_TRs = 5; % TR's scan a few more volumes for HRF to catch up
Stm(1).RetMap.StimType{1} = 'checkerboard'; % face / walker / checkerboard / none
Stm(1).RetMap.Checker.Size = 15; % radius deg (limited of course by screen size)
Stm(1).RetMap.Checker.Sector = [-180 180]; % part of the circle that is drawn
Stm(1).RetMap.Checker.OnOff_TRs = [5 5]; % TR's on , TR's off
Stm(1).RetMap.nCycles = 10; % 0=unlimited
Stm(1).RetMap.Checker.chsz = [6 22.5]; 
Stm(1).RetMap.Checker.FlickFreq_Approx = 4; % Hz 
% size of checks in log factors & degrees respectively = [eccentricity, angle]
Stm(1).RetMap.Checker.centerradius = 0.4;
Stm(1).RetMap.Checker.Colors = [1 1 1; 0 0 0];


Stm(1).RetMap.Checker.LoadFromFile = true;
Stm(1).RetMap.Checker.SaveToFile = false;
Stm(1).RetMap.Checker.FileName = 'Checkerboard_MOCK.mat';

% Logfolder
Stm(1).LogFolder = fullfile('Retinotopy','Checkerboard');

%% 
%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;