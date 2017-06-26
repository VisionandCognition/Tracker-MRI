function StimSettings_CurveMapping

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
%eval('StimSettings'); % loads the default parameters
eval('StimSettings__Defaults__'); % loads the default parameters

% Stimulus specific timing (in ms)
CtrlParams = StimObj.DefaultCtrlParams;
CtrlParams.SwitchDur = 1300; % (200) duration of alternative orientation

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs ...
%  post_switch_duration_in_which_nothing_happens]
CtrlParams.EventPeriods = [1000 0 300]; % Params.EventPeriods = [3000 0 300];
CtrlParams.prefixPeriod = 500; % not just for fixation!


CtrlParams.rewardMultiplier = 0.6;
CtrlParams.BlockSize = 6;

curvecontrol = CurveTracingTitratedTask(CtrlParams, ...
    'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT');

Stm(1).RestingTask = CurveTracingBlockByTitratedTask(CtrlParams, ...
    'StimSettings/HandResponseTask_NoStimulus.csv', ...
    'No Stim Hand Response', ...
    'CombinedStim');

Stm(1).KeepSubjectBusyTask = curvemapping;

Stm(1).tasksToCycle = [...t
    {curvecontrol} ... curve control
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvemapping;
Stm(1).alternateWithRestingBlocks = true;




StimObj.Stm = Stm;