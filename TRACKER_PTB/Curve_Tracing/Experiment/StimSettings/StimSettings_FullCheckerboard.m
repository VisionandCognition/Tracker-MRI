global StimObj

%% Load defaults ==========================================================
% The *parameters* for the classes are saved to StimSettings__Defaults__.
% The order of the blocks are defined below.
eval('StimSettings__Defaults__'); % loads the default parameters

Stm = StimObj.Stm;

% Checkerboard stimuli ----------------------------------------------------

CtrlParams = StimObj.DefaultCtrlParams;
CtrlParams.SwitchDur = 1300; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
CtrlParams.EventPeriods = [3000 0 300]; % Params.EventPeriods = [3000 0 300];
CtrlParams.prefixPeriod = 500; % not just for fixation!


CtrlParams.rewardMultiplier = 1.0;
CtrlParams.BlockSize = 3;

CheckerboardParams = CtrlParams;
CheckerboardParams.LoadFromFile = false;

RetMap.PreDur_TRs = 5; % TR's NB! With a TR of 3 sec, this is 15 s
RetMap.PostDur_TRs = 5; % TR's scan a few more volumes for HRF to catch up
RetMap.StimType{1} = 'checkerboard'; % face / walker / checkerboard / none
RetMap.Checker.Size = 15; % radius deg (limited of course by screen size)
RetMap.Checker.Sector = [-180 180]; % part of the circle that is drawn
RetMap.Checker.OnOff_TRs = [5 5]; % TR's on , TR's off
RetMap.nCycles = 10; %20; % 0=unlimited
RetMap.Checker.chsz = [6 22.5]; 
RetMap.Checker.FlickFreq_Approx = 4; % Hz 
% size of checks in log factors & degrees respectively = [eccentricity, angle]
RetMap.Checker.centerradius = 0.4;
RetMap.Checker.Colors = [1 1 1; 0 0 0];

RetMap.Checker.LoadFromFile = true;
RetMap.Checker.SaveToFile = true;
RetMap.Checker.FileName = 'Checkerboard_[MRI_SETUP].mat';
CheckerboardParams.RetMap = RetMap;


%curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
Stm(1).KeepSubjectBusyTask = FullscreenCheckerboard(CheckerboardParams, ...
    'StimSettings/HandResponseTask_NoStimulus.csv', ...
    'Keep busy');

checkerboard = FullscreenCheckerboard(CheckerboardParams, ...
    'StimSettings/HandResponseTask_NoStimulus.csv');

Stm(1).RestingTask = CurveTracingBlockByTitratedTask(CtrlParams, ...
    'StimSettings/HandResponseTask_NoStimulus.csv', ...
    'No Stim Hand Response', ...
    'CombinedStim');

Stm(1).tasksToCycle = [...
    repmat({checkerboard}, 1, 1) ... checkerboard
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = Stm(1).RestingTask;
Stm(1).alternateWithRestingBlocks = true;

Stm(1).checkerboard = checkerboard;

Stm(1).task = Stm(1).RestingTask; % task used for initialization

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;