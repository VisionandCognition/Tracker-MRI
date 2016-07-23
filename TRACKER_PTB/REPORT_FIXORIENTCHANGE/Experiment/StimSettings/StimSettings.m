%StimSettings
global StimObj

% Refreshrate 
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1

% Fixation
Stm(1).FixWinSize = 2; % in deg

% A vertical bar that is randomly set to horizontal
Stm(1).Size = [.5 .1]; % [length width] in deg
Stm(1).Orientation = [1 0]; % [def alt] 0=hor, 1=vert

% Stimulus position can be toggled with 1-5 keys
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-5 0]; % deg from center (-=left/down)
Stm(1).Position{3} = [0 -5]; % deg from center (-=left/down)
Stm(1).Position{4} = [5 0]; % deg from center (-=left/down)
Stm(1).Position{5} = [0 5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 50; % set zero for manual cycling
Stm(1).Color = [0 1 0]; % [R G B] 0-1

% A circular noise patch
Stm(1).NoiseSize = 5; % circular patch diameter in deg
Stm(1).NoiseContrast = 1; % 0-1
Stm(1).NoiseDefaultOn = true; % [toggle with "B" key]

% Stimulus specific timing (in ms)
Stm(1).SwitchDur = 250; % duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ...
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
Stm(1).EventPeriods = [500 1500 1000];
Stm(1).ShowDistractBar = true; % show vertical bar [toggle with "D" key]

% Response time window
Stm(1).AutoReward = true; % give a reward if response is correct
Stm(1).OnlyStartTrialWhenBeamIsNotBlocked = false;
Stm(1).BreakOnFalseHit = true; % if AutoReward=true, trial is broken off on false hit
Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;