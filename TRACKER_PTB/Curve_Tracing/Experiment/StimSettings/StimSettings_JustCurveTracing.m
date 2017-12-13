function StimSettings_JustCurveTracing

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings__Defaults__'); % loads the default parameters

Params = StimObj.DefaultParams;
unsaturatedColor = [0.2 0.2 0.2; 0.2 0.2 0.2; .3 .3 .3];
satLevel = 0;
% satLevel = 0.075/12;
%satLevel = 2/12;
Params.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

QuickParams = Params;

%QuickParams.EventPeriods = [2200 1000 300];
QuickParams.EventPeriods = [1500 700 300];
%QuickParams.rewardMultiplier = .5; % 0.5;
QuickParams.SwitchDur = 600;
QuickParams.ResponseAllowed = [100 QuickParams.SwitchDur+100]; % [after_onset after_offset] in ms

QuickParams.maxSideProb = 0.75;
QuickParams.sideRespAprioriNum = 2;

% use non-blocked curvetracing
%curvetracing = CurveTracingJoystickTask(QuickParams, 'StimSettings/CurveTracingJoyStickTask.csv');
curvetracing = CurveTracingJoystickTask(QuickParams, 'StimSettings/CurveTracingJoyStickTask.csv', 'Quick CT', 'GroupConnections', true);
Stm(1).KeepSubjectBusyTask = curvetracing;
Stm(1).RestingTask = curvetracing;

Stm(1).tasksToCycle = [...
    {curvetracing} ... curve tracing
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvetracing;
Stm(1).alternateWithRestingBlocks = false;

StimObj.Stm = Stm;
