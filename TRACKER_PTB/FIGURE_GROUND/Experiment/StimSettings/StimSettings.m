%StimSettings
global StimObj

% using Stm(1) despite there only being one Stm for compatibility with 
% older code in the RETINOTOPY folder

%% ========================================================================
% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
%Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1
Stm(1).BackColor = (88/255).*[1 1 1]; % [R G B] 0-1
% Leuven retinotopy clips have a background of 88 out of 256

% Fixation ----------------------------------------------------------------
Stm(1).FixDotSize = 0.15;
Stm(1).FixDotSurrSize = 0.75;
Stm(1).FixDotCol = [1 0 0;1 0 0]; %[RGB if not fixating; RGB fixating]

% Fixation position can be toggled with 1-5 keys --------------------------
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-10 -5]; % deg from center (-=left/down)
Stm(1).Position{3} = [+10 -5]; % deg from center (-=left/down)
Stm(1).Position{4} = [-10 +5]; % deg from center (-=left/down)
Stm(1).Position{5} = [+10 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 0; % set zero for manual cycling

% Retinotopic mapping stimulus --------------------------------------------
Stm(1).RandomizeStim=false;
Stm(1).nRepeatsStimSet=1;

Stm(1).StimType{1} = 'FigureGround'; 
Stm(1).StimType{2} = 'texture'; % texture / dots

% Figure/Ground stimuli
Stm(1).MoveGnd.Do = false;
Stm(1).MoveGnd.SOA = 1.000; % secs
Stm(1).MoveGnd.nFrames = 0.500; % secs
Stm(1).MoveGnd.XY = [0 0.2]; % deg
% texture: [X Y]
% dots: [parallel orthogonal]

Stm(1).RefreshSeed = 1.000; % s set to 0 for no refresh
Stm(1).InvertPolarity = true;

Stm(1).SaveToFile = true;
Stm(1).LoadFromFile = false;
Stm(1).FileName = 'FigGnd_Triangles.mat';

% Logfolder
Stm(1).LogFolder = 'C:\Users\NINuser\Documents\Log_CK\FigGnd\Default';

% Timing --
Stm(1).stim_rep = 5; % BLOCK: n stim + n backgrounds
Stm(1).stim_TRs = 2; % stim duration in TRs
Stm(1).int_TRs =  1; % interval duration in TRs

%% This only applies to newly created stim ================================
% Background definitions --
Stm(1).Gnd(1).backcol = [1 1 1]; % [R G B] 0-1
Stm(1).Gnd(1).lines.length = 20;
Stm(1).Gnd(1).lines.width = 2;
Stm(1).Gnd(1).lines.density = 0.6; % 0-1
Stm(1).Gnd(1).lines.color = [0 0 0];
Stm(1).Gnd(1).lines.orient = 45;
% -
Stm(1).Gnd(1).dots.size = []; % 5; % maxes at 10 if we want larger we need to draw rects
Stm(1).Gnd(1).dots.density = []; % 0.7; % 0-1
Stm(1).Gnd(1).dots.color = []; % [0 0 0];
Stm(1).Gnd(1).dots.type = []; % 0; % fast square dots
% -
Stm(1).Gnd(1).NumSeeds = 1;
% -
Stm(1).Gnd(2) = Gnd(1);
Stm(1).Gnd(2).orient = 135;
    
% Figure definitions --
% inherits texture feats from gnd with same index
% line density, colors, length & width
Stm(1).Fig(1).size = [300 300]; % in case of triangle only take (1)
Stm(1).Fig(1).position = [-300 0];
Stm(1).Fig(1).orient = Gnd(1).orient + 90;
Stm(1).Fig(1).shape = 'Triangle_up';
% 'Rectangle', 'Oval', 'Triangle_up', 'Triangle_down'
% -
Stm(1).Fig(2) = Fig(1); 
Stm(1).Fig(2).position = [300 0];
% -
Stm(1).Fig(3) = Fig(1);
Stm(1).Fig(3).orient = Gnd(2).orient + 90;
% -
Stm(1).Fig(4) = Fig(3);
Stm(1).Fig(4).position = [300 0];
% -
Stm(1).Fig(5) = Fig(1);
Stm(1).Fig(5).shape = 'Triangle_down';
% -
Stm(1).Fig(6) = Fig(2);
Stm(1).Fig(6).shape = 'Triangle_down';
% -
Stm(1).Fig(7) = Fig(3);
Stm(1).Fig(7).shape = 'Triangle_down';
% -
Stm(1).Fig(8) = Fig(4);
Stm(1).Fig(8).shape = 'Triangle_down';
    
% Intermediate background --
Stm(1).IntGnd = Gnd(1);
Stm(1).IntGnd.orient = 90;
    
% Stimulus combination to include --
Stm(1).FigGnd{1} = [1 1];
Stm(1).FigGnd{2} = [2 1];
Stm(1).FigGnd{3} = [3 2];
Stm(1).FigGnd{4} = [4 2];
Stm(1).FigGnd{5} = [5 1];
Stm(1).FigGnd{6} = [6 1];
Stm(1).FigGnd{7} = [7 2];
Stm(1).FigGnd{8} = [8 2];

Stm(1).randomize_stim = true;





Stm(1).PreDur_TRs = 5; % volumes
Stm(1).PostDur_TRs = 5; % volumes
Stm(1).nCycles = 2; % 0=unlimited
Stm(1).RetMap.nSteps = 32; 

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;