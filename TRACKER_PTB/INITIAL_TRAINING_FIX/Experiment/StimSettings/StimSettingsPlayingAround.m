f%StimSettings
global StimObj

% Background --------------------------------------------------------------
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1

% Fixation ----------------------------------------------------------------
Stm(1).FixWinSize = 3; % in deg
Stm(1).RequireFixation = true;
Stm(1).FixDotSize = 0.3;
Stm(1).FixDotCol = [.35 .35 .35; 0 0 0; .4 .4 .4]; %[RGB if not fixating; RGB fixating]

% A vertical bar that is randomly set to horizontal
length = 0.2; % .02
Stm(1).Size = length*[1, .25] + [0, 0.020]; % [length width] in deg
Stm(1).Orientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Stm(1).Color = [0.6 0.7 0.7]; % [R G B] 0-1

% Curve tracing stimulus
Stm(1).TraceCurveCol = [0 0 0];
Stm(1).TraceCurveWidth = 4;
Stm(1).UnattdAlpha = [-0.05 0];
Stm(1).UnattdAlpha_TargetAtFix = [-0.05 0];

% Paw indicator
Stm(1).RequireSpecificPaw = true;
Stm(1).PawIndSize = 2.5;
%Stm(1).PawIndOffset = [3.5 2.5];
Stm(1).PawIndOffsetX = [-3 3]; % [min max]
Stm(1).PawIndOffsetY = [2.0 5.0]; % [min max]
Stm(1).PawIndCol = [0 .75 0; .8 0 .55]; % colors for the left and right target

Stm(1).SwitchToLPawProb = [0.5 0.0]; % [prev. correct, prev. incorrect]
Stm(1).SwitchToRPawProb = [0.5 0.0]; % [prev. correct, prev. incorrect]
Stm(1).TrialsWithoutSwitching = 0; % Wait at least this number of trials before switching

% Stimulus position can be toggled with 1-5 keys
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-4 0]; % deg from center (-=left/down)
Stm(1).Position{3} = [0 -4]; % deg from center (-=left/down)
Stm(1).Position{4} = [4 0]; % deg from center (-=left/down)
Stm(1).Position{5} = [0 4]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 100000; % set zero for manual cycling

% A circular noise patch
Stm(1).NoiseSize = 1.1; % circular patch diameter in deg
Stm(1).NoiseContrast = 0.01; % 0-1
Stm(1).NoiseDefaultOn = false; % [toggle with "B" key]

% Stimulus specific timing (in ms)
Stm(1).SwitchDur = 400; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
Stm(1).EventPeriods = [500 1500 250];
Stm(1).ShowDistractBar = true; % show vertical bar [toggle with "D" key]

% Response time window
Stm(1).AutoReward = true; % give a reward if response is correct
Stm(1).OnlyStartTrialWhenBeamIsNotBlocked = true;
Stm(1).NumBeams = 2;
Stm(1).BreakOnFalseHit = true; % if AutoReward=true, trial is broken off on false hit
Stm(1).ResponseAllowed = [100 Stm(1).SwitchDur+100]; % [after_onset after_offset] in ms
%Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms
Stm(1).BreakDuration = 600; % 1500 additional waiting period for early / false hits

Stm(1).ProbConsolatoryReward = 0.0;
Stm(1).ProbFixationReward = 0.0;

Stm(1).TASK_TARGET_AT_CURVE = 1;
Stm(1).TASK_TARGET_AT_FIX = 2;
Stm(1).Task = Stm(1).TASK_TARGET_AT_FIX;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;