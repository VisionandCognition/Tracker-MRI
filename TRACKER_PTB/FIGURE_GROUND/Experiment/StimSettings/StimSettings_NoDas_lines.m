%StimSettings
global StimObj

% using Stm(1) despite there only being one Stm for compatibility with 
% older code in the RETINOTOPY folder

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm.UsePreDefFlipTime=false; %else as fast as possible
Stm.FlipTimePredef = 1/75;
Stm.ScreenUpdateTime = 0.020; % secs

% Background --------------------------------------------------------------
%Stm.BackColor = [.5 .5 .5]; % [R G B] 0-1
Stm.BackColor = [.667 .667 .667]; % [R G B] 0-1, from Retinotopy
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm.FixDotSize = 0.1;
Stm.FixDotSurrSize = 0.3;
Stm.FixDotCol = [.5 0 0;1 0 0]; %[RGB if not fixating; RGB fixating]

% Fixation position can be toggled with 1-5 keys --------------------------
Stm.Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm.Position{2} = [-10 -5]; % deg from center (-=left/down)
Stm.Position{3} = [+10 -5]; % deg from center (-=left/down)
Stm.Position{4} = [-10 +5]; % deg from center (-=left/down)
Stm.Position{5} = [+10 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm.CyclePosition = 0; % set zero for manual cycling

% Retinotopic mapping stimulus --------------------------------------------
Stm.RandomizeStim=true;
Stm.Descript = 'FigGnd';
Stm.StimType{1} = 'FigureGround'; 
Stm.StimType{2} = 'lines'; % lines / dots

% Figure/Ground stimuli
Stm.MoveStim.Do = false;
Stm.MoveStim.SOA = 0.250; % secs
Stm.MoveStim.nFrames = 10; % frames
Stm.MoveStim.XY = 1*[0.1 0.1]; % deg
% texture: [X Y]
% dots: [parallel orthogonal]

Stm.RefreshSeed = 0; % s set to 0 for no refresh

Stm.InvertPolarity = false;
Stm.RefreshPol = 0.500;

Stm.SaveToFile = true;
Stm.LoadFromFile = false; %% Overwrites settings
Stm.FileName = 'teststim_lines.mat';

% Logfolder
Stm.LogFolder = 'FigGnd';

%% This only applies to newly created stim ================================
% Background definitions --------------------------------------------------
Stm.Gnd_all.backcol = [1 1 1]; % [R G B] 0-1
Stm.Gnd_all.lines.length = 50; % pix
Stm.Gnd_all.lines.width = 4; % pix
Stm.Gnd_all.lines.density = 0.7; % 0-1
Stm.Gnd_all.lines.color = [0 0 0];
%
Stm.Gnd_all.dots.size = 5; % 5; 
% maxes at 10 if we want larger we need to draw rects
Stm.Gnd_all.dots.density = 0.5; % 0.7; % 0-1
Stm.Gnd_all.dots.color = [0 0 0]; % [0 0 0];
Stm.Gnd_all.dots.type = 0; % 0; % fast square dots
%
Stm.Gnd_all.NumSeeds = 1;
%
Stm.Gnd = Stm.Gnd_all;

% Individual stimulus definitions -----
Stm.Gnd(1).orient = 45;
% -
Stm.Gnd(2) = Stm.Gnd(1);
Stm.Gnd(2).orient = -45;
    
% Figure definitions ------------------------------------------------------
% inherits texture feats from gnd
Stm.Fig_all.orientations = [-Stm.Gnd(1).orient -Stm.Gnd(2).orient];
%
Stm.Fig(1).size = [6 4]; % DVA in case of triangle only take (1)
Stm.Fig(1).position = [0 -0.5]; % DVA
Stm.Fig(1).ishole = false;
Stm.Fig(1).ori_ind = 1;
Stm.Fig(1).orient = ...
    Stm.Fig_all.orientations(Stm.Fig(1).ori_ind);
Stm.Fig(1).shape = 'N';
% 'Rectangle', 'Oval', 'Triangle_up', 'Triangle_down', 'N','U'
Stm.Fig(1).NU_gapsize = [2 3]; % [width height] >> only applies to NU and U
% -
Stm.Fig(2) = Stm.Fig(1); 
Stm.Fig(2).position = [-2 -0.5]; % DVA
% -
Stm.Fig(3) = Stm.Fig(1);
Stm.Fig(3).position = [2 -0.5]; % DVA
% -
Stm.Fig(4) = Stm.Fig(3);
Stm.Fig(4).position = [-4 -0.5]; % DVA
% -
Stm.Fig(5) = Stm.Fig(1);
Stm.Fig(5).position = [4 -0.5]; % DVA

% --
Stm.Fig(6) = Stm.Fig(1);
Stm.Fig(6).ori_ind = 2;
Stm.Fig(6).orient = ...
    Stm.Fig_all.orientations(Stm.Fig(6).ori_ind);
% -
Stm.Fig(7) = Stm.Fig(6); 
Stm.Fig(7).position = [-2 -0.5]; % DVA
% -
Stm.Fig(8) = Stm.Fig(6);
Stm.Fig(8).position = [2 -0.5]; % DVA
% -
Stm.Fig(9) = Stm.Fig(6);
Stm.Fig(9).position = [-4 -0.5]; % DVA
% -
Stm.Fig(10) = Stm.Fig(6);
Stm.Fig(10).position = [4 -0.5]; % DVA


% Intermediate background --
Stm.IntGnd = Stm.Gnd_all;
Stm.IntGnd.orient = 90;
    
% Stimulus combination to include --
% >> always followed by background only <<
% [figure ground; figure ground]
% alternating between the 1st and 2nd pair
Stm.FigGnd{1} = [1 1; 6 2]; 
Stm.FigGnd{2} = [0 1; 0 2];
Stm.FigGnd{3} = [2 1; 7 2];
Stm.FigGnd{4} = [0 1; 0 2];
Stm.FigGnd{5} = [3 1; 8 2];
Stm.FigGnd{6} = [0 1; 0 2];
Stm.FigGnd{7} = [4 1; 9 2];
Stm.FigGnd{8} = [0 1; 0 2];
Stm.FigGnd{9} = [5 1; 10 2];
Stm.FigGnd{10} = [0 1; 0 2];

Stm.InterLeave_FigGnd = false;
% if true, do fig - gnd - fig - gnd - fig - etc...
% if false, only do figures

% Timing --
Stm.stimblockdur = 10;
Stm.stim_TRs = 0.4; % stim duration in TRs (2.5s)
Stm.int_TRs =  0.0; % interval duration in TRs 

nrep = ceil(Stm.stimblockdur./((Stm.stim_TRs+Stm.int_TRs)*2.5));
Stm.stim_rep = nrep; %16; % BLOCK: 
Stm.firstint_TRs =  0; % interval duration in TRs 

Stm.RandomizeStimMode = 2; 
% 0: no randomnisation
% 1: full randomnisation
% 2: randomnize pairs, so keep 1:2, 3:4, etc together
%    useful to create random block design
%    every 2nd configuration should be ground only

Stm.PreDur_TRs = 2;%5; % volumes
Stm.PostDur_TRs = 2;%5; % volumes
Stm.nRepeatsStimSet = 1;%2; % 0=unlimited

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;