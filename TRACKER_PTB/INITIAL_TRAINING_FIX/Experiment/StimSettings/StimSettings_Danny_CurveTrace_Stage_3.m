%StimSettings
global StimObj
% The main goal of this stage is for the subject to start ignoring the
% target without a line going to it.
% The main variable to change is UnattdAlpha, the values should go to 1.
% The alpha used for the distractors is a random value between the min and
% max values in this variable.

%% Refreshrate ------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

%% Background -------------------------------------------------------------
Stm(1).BackColor = [.5 .5 .5]; % [R G B] 0-1

%% Fixation ---------------------------------------------------------------
Stm(1).FixWinSize = 3; % in deg
Stm(1).FixDotSize = 0.3; % 0.3;
Stm(1).FixDotCol = [0 0 0; 0 0 0; .1 .1 .1]; %[RGB if not fixating; RGB fixating]

%% A vertical bar that is randomly set to horizontal ----------------------
length = 0.16; %0.16;
Stm(1).Size = length*[1, .25] + [0, 0.01]; % [length width] in deg
Stm(1).Orientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Stm(1).Color = [0.6 0.7 0.7]; % [R G B] 0-1

%% Curve tracing stimulus -------------------------------------------------
angle_rand = 0; %50;
Stm(1).CurveAnglesAtFP = [...
    180-angle_rand, 180+angle_rand;
    -angle_rand, +angle_rand;
    ];

Stm(1).TraceCurveCol = [0.1 0.1 0.1];
Stm(1).TraceCurveWidth = 6; % pixels
Stm(1).UnattdAlpha = [1.0 1.0]; % min should go to 1, with better training
Stm(1).UnattdAlpha_TargetAtFix = [0];
Stm(1).AlphaPreSwitch = 0.0; %1.0;
Stm(1).AlphaPreSwitch_dist = [0.5 0.5]; %depends on next statement
% alternatively make it consistent with following indicator
Stm(1).AlphaPreSwitch_NeutralEqualsIndicator = true;
Stm(1).PostSwitchJointAlpha = [1]; % max should go to 0, with better training

if isfield(Stm(1), 'CurveConnectionPosX')
    Stm(1) = rmfield(Stm(1), 'CurveConnectionPosX'); % disable
end
Stm(1).CurveAngleGap = 90; % (0,90]

Stm(1).DisconnectedCurveLength = 0.75;

%% Paw indicator ----------------------------------------------------------
Stm(1).RequireSpecificPaw = true;

Stm(1).PawIndSize = 1;

target_offset = 2.25; % start with 0, go to 1 or higher
Stm(1).PawIndPositions = [ -target_offset 0; target_offset 0 ];
Stm(1).PawIndSize = target_offset/4 + 0.5;

% %Stm(1).PawIndOffset = [3.5 2.5]; % not used
% Stm(1).PawIndOffsetX = [-2 5]; % [min max] % no longer used used!
% Stm(1).PawIndOffsetY = [0.0 0.0]; % [min max] % no longer used used!
% Stm(1).PawIndPositions = [ -1 0; 1 0 ];

% Show the subject which response he is currently giving
% Doesn't seem to help.
Stm(1).LiftedPawIndPositions = [ -1 1; 1 1 ] * 5;
Stm(1).LiftedPawIndSize = 0; % 2; ------------ Disable lifted paw indicator
Stm(1).DisplayChosenTargetDur = 0;


Stm(1).CurveAlpha = [1 1 1 1; 1 1 1 1]; % [preswitch; postswitch] ?????
Stm(1).PawIndAlpha = [1 1 1 1; 1 1 1 1];
Stm(1).NumOfPawIndicators = 2; % Can't be more than the number of PawIndPositions!
Stm(1).DistractBranchConnAlpha = 1;
Stm(1).CurveConnectionPosX = [1 1 1 1];

%Stm(1).PawIndCol = 0.2.*[0 .7 0; .9 .2 .2]; % colors for the left and right target
%Stm(1).PawIndCol = 0.1*[.9 1 .9;1 .9 .9]; % colors for the left and right target
Stm(1).PawIndCol = 0.1*[1 1 1;1 1 1; 1 1 1]; % colors for the left and right target and place holder

% You probably want Stm(1).SwitchToLPawProb(1) + Stm(1).SwitchToRPawProb(1) = 1.0.
% This would mean that when a trial is correct, there is a probability
% of Stm(1).SwitchToLPawProb(1) of the next trial being left (regardless
% of what the previous/current trial was).
% You may also want Stm(1).SwitchToLPawProb(2) = Stm(1).SwitchToRPawProb(2)
% and <= 0.5. Decreasing these probabilities will increase the probability
% of repeating the incorrect trial - which you may want to do regardless of
% which hand is used.
if false
    Stm(1).SwitchToLPawProb = [0.7 0.3]; % [prev. correct, prev. incorrect]
    Stm(1).SwitchToRPawProb = [0.7 0.3]; % [prev. correct, prev. incorrect]
else
    % Re-parameterize ....
    pLeftTarget = 0.5; % probability of left hand target when correct
    pRepeatIncorrect = 0.5; % probability of repeating current target when incorrect
    
    Stm(1).SwitchToLPawProb = [pLeftTarget, 1-pRepeatIncorrect]; % [prev. correct, prev. incorrect]
    Stm(1).SwitchToRPawProb = [1-pLeftTarget, 1-pRepeatIncorrect]; % [prev. correct, prev. incorrect]
end

% TrialsWithoutSwitching - Wait at least this number of correct trials
% before switching. 0 means no waiting. 1 means there should be 2 correct
% trials before using the above switch probabilities.
Stm(1).TrialsWithoutSwitching = 0; 

%% Stimulus position can be toggled with 1-5 keys -------------------------
Stm(1).Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm(1).Position{2} = [-4 0]; % deg from center (-=left/down)
Stm(1).Position{3} = [0 -4]; % deg from center (-=left/down)
Stm(1).Position{4} = [4 0]; % deg from center (-=left/down)
Stm(1).Position{5} = [0 4]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm(1).CyclePosition = 100000; % set zero for manual cycling

%% A circular noise patch -------------------------------------------------
Stm(1).NoiseSize = 1.1; % circular patch diameter in deg
Stm(1).NoiseContrast = 0.1; % 0-1
Stm(1).NoiseDefaultOn = false; % [toggle with "B" key]

%% Stimulus specific timing (in ms) ---------------------------------------
Stm(1).SwitchDur = 5000; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
%Stm(1).EventPeriods = [2500 1500 300];
Stm(1).EventPeriods = [500 750 500];
Stm(1).ITI = 500;

Stm(1).ShowDistractBar = true; % show vertical bar [toggle with "D" key]

%% Response time window ---------------------------------------------------
Stm(1).AutoReward = true; % give a reward if response is correct
Stm(1).OnlyStartTrialWhenBeamIsNotBlocked = true;
Stm(1).NumBeams = 2;
Stm(1).BreakOnFalseHit = true; % if AutoReward=true, trial is broken off on false hit
Stm(1).ResponseAllowed = [80 Stm(1).SwitchDur+100]; % [after_onset after_offset] in ms
%Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms
Stm(1).BreakDuration = 2000; % 1500 additional waiting period for early / false hits

Stm(1).FalseHitRewardRatio = 0.00; % 0.75; % amount of reward for FH relative to true hit
Stm(1).PawRewardMultiplier = [1 1]; % [left hand response, right hand response]
Stm(1).ProbConsolatoryReward = 0.00;
Stm(1).ProbFixationReward = 0.0;

Stm(1).TASK_TARGET_AT_CURVE = 0;
Stm(1).TASK_TARGET_AT_FIX = 1;
Stm(1).TASK_TARGET_AT_CURVE_NO_DISTRACTOR = 2;
Stm(1).TASK_TARGET_AT_FIX_NO_DISTRACTOR = 3;
Stm(1).TASK_FIXED_TARGET_LOCATIONS = 4; % Red diamond on left, green square on right

Stm(1).TasksToCycle = [Stm(1).TASK_TARGET_AT_CURVE]; %[Stm(1).TASK_FIXED_TARGET_LOCATIONS Stm(1).TASK_FIXED_TARGET_LOCATIONS Stm(1).TASK_TARGET_AT_FIX];
Stm(1).TaskCycleInd = 1;
Stm(1).Task = Stm(1).TasksToCycle(Stm(1).TaskCycleInd);

%% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;