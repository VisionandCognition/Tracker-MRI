%StimSettings
global StimObj
Params = struct;

% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Default ordering of the tasks

Stm(1).alternateWithRestingBlocks = false;
Stm(1).iterateTasks = false;

% Background --------------------------------------------------------------
Params.BGColor = [.5 .5 .5]; % [R G B] 0-1
%Params.BGColor = [.667 .667 .667]; % [R G B] 0-1, from Retinotopy
% >> Equalize color with Eddy's for scanning / paper

% Fixation ----------------------------------------------------------------
Params.FixWinSizeDeg = 3; % <- testing   2.5; % in deg
Params.FixDotSizeDeg = 0.3;

%[RGB if not fixating; RGB fixating; Fixation not required]
Params.FixDotCol = [0 0 0; 0 0 0; .1 .1 .1];

% A vertical bar that is randomly set to horizontal
length = 0.16;
Params.GoBarSizeDeg = length*[1, .25] + [0, 0.01]; % [length width] in deg
Params.GoBarOrientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Params.GoBarColor = [0.6 0.7 0.7]; % [R G B] 0-1

% Curve tracing stimulus
Params.TraceCurveCol = [.1 .1 .1];
% >> Equalize color with Eddy's for scanning / paper
Params.TraceCurveWidth = 9; % 6; % in pixels
%Params.AlphaPreSwitch = 0.0; % 0 = memory / curve tracing task
% Stm(1).PostSwitchJointAlpha = 0; % max should go to 0, with better training
Params.PostSwitchJointAlpha = 1; % max should go to 0, with better training


% Paw indicator
Params.RequireSpecificPaw = true;

extend_curves = false;
train_curves = true;

if train_curves
        Params.PawIndPositions = [...
        -5 -2.5; ...  1 - LEFT TOP (-,-)
        -5  2.5; ...  2 - LEFT BOTTOM (-,+)
         5 -2.5; ...  3 - RIGHT TOP (+,-)
         5  2.5; ...  4 - RIGHT BOTTOM (+,+)
         0  0 ...     5 - center
        ];

    Params.BranchDistDeg = 1.2;
    Params.CurveTargetDistDeg = 1.5;
    
    gap = 1;
    Params.Gap1_deg = [0 gap];
    Params.Gap2_deg = [0 Params.BranchDistDeg] + gap;
elseif extend_curves
    % Extend more of the visual field
    Params.PawIndPositions = [...
        -8 -4; -8 4; ...
        8 -4; 8 4; ...
        0 0 ... center
        ];
    Params.BranchDistDeg = 1.5;
    Params.CurveTargetDistDeg = 1.8;

    gap = 1;
    Params.Gap1_deg = [0 gap/2]; % decrease gap at fixation point
    Params.Gap2_deg = [0 Params.BranchDistDeg] + gap;
else
    Params.PawIndPositions = [...
        -6.6 -3.3; -6.6 3.3; ...
        6.6 -3.3; 6.6 3.3; ...
        0 0 ... center
        ];
    Params.BranchDistDeg = 1.2;
    Params.CurveTargetDistDeg = 1.5;
    
    gap = 1;
    Params.Gap1_deg = [0 gap];
    Params.Gap2_deg = [0 Params.BranchDistDeg] + gap;
end

% Stm(1).PawIndAlpha = [ PreSwitchAlpha target 1 target 2 ... ; 
%                        PostSwitchAlpha target 1 target 2 ... ]
Params.CurveAlpha = [1 1 1 1 1; 1 1 1 1 1];
Params.PawIndAlpha = [1 1 1 1 1; 1 1 1 1 1];
Params.NumOfPawIndicators = 4; % Can't be more than the number of PawIndPositions!
Params.DistractBranchConnAlpha = 1;

ambigCir = 0.1; % was 0.6 -> should be 0.3?
Params.SaturatedPawIndCol = [0 .7 0; .9 .2 .2; ambigCir ambigCir ambigCir]; % colors for the left and right target
%unsaturatedColor = [0.6 0.6 0.6; 0.6 0.6 0.6];
unsaturatedColor = [0.1 0.1 0.1; 0.1 0.1 0.1; ambigCir ambigCir ambigCir];
% >> Equalize color with Eddy's for scanning / paper

%satLevel = 5/6;
%satLevel = 1/12;
%satLevel = 0.075/12;
satLevel = 0;
Params.PawIndCol = satLevel * Params.SaturatedPawIndCol + (1 - satLevel) * unsaturatedColor;

%Stm(1).SwitchToLPawProb = [0.55 0.15]; % [prev. correct, prev. incorrect]
%Stm(1).SwitchToRPawProb = [0.55 0.15]; % [prev. correct, prev. incorrect]

% Stimulus position can be toggled with 1-5 keys
% Params.FixPositionsPix used to be named Stm(1).Center(Par.PosNr,:)
% FixPositionsDeg is used to calculate FixPositionsPix
Params.FixPositionsDeg{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Params.FixPositionsDeg{2} = [-4 0]; % deg from center (-=left/down)
Params.FixPositionsDeg{3} = [0 -4]; % deg from center (-=left/down)
Params.FixPositionsDeg{4} = [4 0]; % deg from center (-=left/down)
Params.FixPositionsDeg{5} = [0 4]; % deg from center (-=left/down)

% Stimulus specific timing (in ms)
Params.SwitchDur = 5000; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
%Params.EventPeriods = [1800 1600 300];
Params.EventPeriods = [1000 750 500];
Params.prefixPeriod = 500; % not just for fixation task!

% Response time window
Params.NumBeams = 2;
Params.ResponseAllowed = [50 Params.SwitchDur+100]; % [after_onset after_offset] in ms
%Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms
Params.BreakDuration = 1000; % 1500 additional waiting period for early / false hits

Stm(1).ProbConsolatoryReward = 0.00; % << How is this implemented? Rewarding 1/100 trials regardless?
Stm(1).ProbFixationReward = 0.0; % << what's this probability?

Params.CurveAnglesAtFP = [ 180; 180; 0; 0]; % UL DL UR DR

%Params.PawIndSizeDeg = [2.5, 2.5, 2.5, 2.5, Params.FixDotSizeDeg];
Params.PawIndSizeDeg = [2 2 2 2, Params.FixDotSizeDeg];
Params.BlockSize = 3;
Params.rewardMultiplier = 1.0;
Params.rewardSideRespMultiplier = [1 1];

% Parameters for titrating the target to require the less used hand to be
% used more often.
Params.maxSideProb = 0.75; % Maximum probability after titrating targets to responses
Params.sideAprioriLeftProb = 0.5;
Params.sideRespAprioriNum = 0.1; % How many unbiased trials are assumed to be "observed" before starting

FixParams = Params;
FixParams.subtrialsInTrial = 8;
FixParams.fixationPeriod = 540;  % just for fixation task
FixParams.postfixPeriod = 0;  % just for fixation task

FixParams.rewardMultiplier = .25; % 0.5;
FixParams.BlockSize = 3; %round(3* 3500 / FixParams.fixationPeriod * FixParams.subtrialsInTrial);


CtrlParams = Params;
CtrlParams.NumOfPawIndicators = 5;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;

StimObj.DefaultParams = Params;
StimObj.DefaultFixParams = FixParams;
StimObj.DefaultCtrlParams = CtrlParams;