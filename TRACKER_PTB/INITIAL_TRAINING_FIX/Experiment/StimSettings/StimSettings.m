%StimSettings
global StimObj

% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1

% Fixation ----------------------------------------------------------------
Stm(1).FixWinSize = 2.5; % in deg
Stm(1).FixDotSize = 0.3;
Stm(1).FixDotCol = [0 0 0; 0 0 0; .1 .1 .1]; %[RGB if not fixating; RGB fixating]

% A vertical bar that is randomly set to horizontal
length = 0.16;
Stm(1).Size = length*[1, .25] + [0, 0.01]; % [length width] in deg
Stm(1).Orientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Stm(1).Color = [0.6 0.7 0.7]; % [R G B] 0-1

% Curve tracing stimulus
Stm(1).TraceCurveCol = [0 0 0];
Stm(1).TraceCurveWidth = 9; % 6;
Stm(1).UnattdAlpha = 1; % min should go to 1, with better training
Stm(1).UnattdAlpha_TargetAtFix = 1;
Stm(1).AlphaPreSwitch = 0.0; % 0 = memory / curve tracing task
% Stm(1).PostSwitchJointAlpha = 0; % max should go to 0, with better training
Stm(1).PostSwitchJointAlpha = 0.5; % max should go to 0, with better training
% Horizontal positions of "Connections" in Curve (edges of gaps)
% [End_of_Fix_Gap/Start_of_straight_line, 
%  End_of_straight_line/start of curve,
%  Midpoint of curve (where curves meet, vertical line)
%  End_of_curve/Beginning of straight line that connects to center of target ]
Stm(1).CurveConnectionPosX = [0.18 0.25 0.5 0.8];

% Size of the gap at the "joint" closest to the target
%Stm(1).CurveAngleGap = 45; % (30,90]
Stm(1).CurveAngleGap = 90; % (30,90]
Stm(1).GapFraction = 0.75;

% Paw indicator
Stm(1).RequireSpecificPaw = true;
Stm(1).PawIndSize = 2.5;
%Stm(1).PawIndOffset = [3.5 2.5];
Stm(1).PawIndOffsetX = [-3 3]; % [min max]
Stm(1).PawIndOffsetY = [2.0 5.0]; % [min max]
Stm(1).PawIndPositions = [...
    -6 -3; -6 3; ...
    6 -3; 6 3 ...
    ] * 1.1;
angle_rand = 40;
Stm(1).CurveAnglesAtFP = [...
    180-angle_rand, 180+angle_rand;
    -angle_rand, +angle_rand;
    ];
% Stm(1).PawIndAlpha = [ PreSwitchAlpha target 1 target 2 ... ; 
%                        PostSwitchAlpha target 1 target 2 ... ]
Stm(1).CurveAlpha = [1 1 1 1; 1 1 1 1];
Stm(1).PawIndAlpha = [1 1 1 1; 1 1 1 1];
Stm(1).NumOfPawIndicators = 4; % Can't be more than the number of PawIndPositions!
Stm(1).DistractBranchConnAlpha = 1;

Stm(1).PawIndCol = [0 .7 0; .9 .2 .2]; % colors for the left and right target

Stm(1).SwitchToLPawProb = [0.55 0.15]; % [prev. correct, prev. incorrect]
Stm(1).SwitchToRPawProb = [0.55 0.15]; % [prev. correct, prev. incorrect]
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
Stm(1).SwitchDur = 5000; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
%Stm(1).EventPeriods = [2500 1500 300];
%Stm(1).EventPeriods = [1400 2100 300];
Stm(1).EventPeriods = [1800 1600 300];
% Stm(1).EventPeriods = [500 0 300];


% Stm(1).Cue_PreSwitchDur = [1400 3500];
% Stm(1).Target_SwitchDur = [1500 2000];
% Stm(1).ITI_PostSwitchDur = [0 500];


Stm(1).ShowDistractBar = true; % show vertical bar [toggle with "D" key]

% Response time window
Stm(1).AutoReward = true; % give a reward if response is correct
Stm(1).OnlyStartTrialWhenBeamIsNotBlocked = true;
Stm(1).NumBeams = 2;
Stm(1).BreakOnFalseHit = true; % if AutoReward=true, trial is broken off on false hit
Stm(1).ResponseAllowed = [100 Stm(1).SwitchDur+100]; % [after_onset after_offset] in ms
%Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms
Stm(1).BreakDuration = 1000; % 1500 additional waiting period for early / false hits

Stm(1).ProbConsolatoryReward = 0.01;
Stm(1).ProbFixationReward = 0.0;

Stm(1).TASK_TARGET_AT_CURVE = 0;
Stm(1).TASK_TARGET_AT_FIX = 1;
Stm(1).TASK_TARGET_AT_CURVE_NO_DISTRACTOR = 2;
Stm(1).TASK_TARGET_AT_FIX_NO_DISTRACTOR = 3;
Stm(1).TASK_FIXED_TARGET_LOCATIONS = 4; % Red diamond on left, green square on right
Stm(1).TaskNames_1 = {'Curve tracing', 'Control task', ...
    'Curve tracing w/o distractor', 'Control task w/o distractor', ...
    'Fixed cue location task' ...
    };
Stm(1).TaskName = @(i) Stm(1).TaskNames_1{i+1};

Stm(1).TaskRewardMultiplier = [1.4, 1/1.4];
Stm(1).TasksToCycle = [Stm(1).TASK_TARGET_AT_CURVE Stm(1).TASK_TARGET_AT_FIX ];
Stm(1).TaskCycleInd = 1;
Stm(1).Task = Stm(1).TasksToCycle(Stm(1).TaskCycleInd);

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;