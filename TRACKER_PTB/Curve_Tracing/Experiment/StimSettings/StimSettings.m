%StimSettings
global StimObj
Params = struct;

% Refreshrate -------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

% Background --------------------------------------------------------------
Params.BGColor = [.5 .5 .5]; % [R G B] 0-1

% Fixation ----------------------------------------------------------------
Params.FixWinSizeDeg = 3.5; % <- testing   2.5; % in deg
Params.FixDotSizeDeg = 0.3;

%[RGB if not fixating; RGB fixating; Fixation not required]
Params.FixDotCol = [0 0 0; 0 0 0; .1 .1 .1];

% A vertical bar that is randomly set to horizontal
length = 0.16;
Params.GoBarSizeDeg = length*[1, .25] + [0, 0.01]; % [length width] in deg
Params.GoBarOrientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Params.GoBarColor = [0.6 0.7 0.7]; % [R G B] 0-1

% Curve tracing stimulus
Params.TraceCurveCol = [0 0 0];
Params.TraceCurveWidth = 9; % 6;
%Params.AlphaPreSwitch = 0.0; % 0 = memory / curve tracing task
% Stm(1).PostSwitchJointAlpha = 0; % max should go to 0, with better training
Params.PostSwitchJointAlpha = 1; % max should go to 0, with better training

gap = 1;
Params.BranchDistDeg = 1.2;
Params.Gap1_deg = [0 gap];
Params.Gap2_deg = [0 Params.BranchDistDeg] + gap;
Params.CurveTargetDistDeg = 1.5;

% Paw indicator
Params.RequireSpecificPaw = true;
%Stm(1).PawIndOffset = [3.5 2.5];
Params.PawIndPositions = [...
    -6 -3; -6 3; ...
    6 -3; 6 3; ...
    0 0 ... center
    ] * 1.1;

% Stm(1).PawIndAlpha = [ PreSwitchAlpha target 1 target 2 ... ; 
%                        PostSwitchAlpha target 1 target 2 ... ]
Params.CurveAlpha = [1 1 1 1 1; 1 1 1 1 1];
Params.PawIndAlpha = [1 1 1 1 1; 1 1 1 1 1];
Params.NumOfPawIndicators = 4; % Can't be more than the number of PawIndPositions!
Params.DistractBranchConnAlpha = 1;

Params.PawIndCol = [0 .7 0; .9 .2 .2]; % colors for the left and right target
unsaturatedColor = [0.6 0.6 0.6; 0.6 0.6 0.6];
satLevel = 5/6;
Params.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

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
Params.SwitchDur = 1300; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
%Params.EventPeriods = [1800 1600 300];
Params.EventPeriods = [3000 0 300];
Params.prefixPeriod = 500; % not just for fixation!

% Response time window
Params.NumBeams = 2;
Params.ResponseAllowed = [100 Params.SwitchDur+100]; % [after_onset after_offset] in ms
%Stm(1).ResponseAllowed = [100 4000]; % [after_onset after_offset] in ms
Params.BreakDuration = 1000; % 1500 additional waiting period for early / false hits

Stm(1).ProbConsolatoryReward = 0.01;
Stm(1).ProbFixationReward = 0.0;

Params.CurveAnglesAtFP = [ 180; 180; 0; 0];

Params.PawIndSizeDeg = [2.5, 2.5, 2.5, 2.5, Params.FixDotSizeDeg];
Params.BlockSize = 3;
Params.rewardMultiplier = 1.0;

% Parameters for titrating the target to require the less used hand to be
% used more often.
Params.maxSideProb = 0.75; % Maximum probability after titrating targets to responses
Params.unbiasedRespApriori = 0.1; % How many unbiased trials are assumed to be "observed" before starting

FixParams = Params;
FixParams.rewardMultiplier = 1.0; % 0.5;
FixParams.subtrialsInTrial = 8;
FixParams.fixationPeriod = 500;  % just for fixation task
FixParams.postfixPeriod = 0;  % just for fixation task

FixParams.rewardMultiplier = .12; % 0.5;
FixParams.BlockSize = 2; %round(3* 3500 / FixParams.fixationPeriod * FixParams.subtrialsInTrial);


CtrlParams = Params;
CtrlParams.NumOfPawIndicators = 5;

%curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
% Stm(1).KeepSubjectBusyTask = CurveTracingJoystickTask(Params, ...
%     'StimSettings/CurveTracingJoyStickTask.csv', ...
%     'Keep busy');
if isfield(Stm(1),'KeepSubjectBusyTask')
    Stm(1) = rmfield(Stm(1),'KeepSubjectBusyTask');
end

curvetracing = CurveTracingBlockTitratedTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecatch = CurveTracingCatchBlockTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecontrol = CurveTracingJoystickTask(CtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv');
fixation = FixationTask(FixParams);
Stm(1).RestingTask = fixation;

    %repmat({curvetracing}, 1, 4*4) ... curve tracing
    %repmat({curvecontrol}, 1, 1*4) ... control
    %repmat({fixation}, 1, 1*4) ... fixation
    %{curvecatch} ... catch trial
Stm(1).tasksToCycle = [...
    repmat({curvetracing}, 1, 4*2) ... curve tracing
    repmat({curvecontrol}, 1, 1*2) ... control
    repmat({fixation}, 1, 1*2) ... fixation
    {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = Stm(1).RestingTask;
Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;