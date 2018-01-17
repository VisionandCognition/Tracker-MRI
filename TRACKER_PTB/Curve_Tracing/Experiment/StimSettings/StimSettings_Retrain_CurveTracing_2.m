global StimObj

%% Load defaults ==========================================================
% The *parameters* for the classes are saved to StimSettings__Defaults__.
% The order of the blocks are defined below.
eval('StimSettings__Defaults__'); % loads the default parameters

Stm = StimObj.Stm;

TargetParams = StimObj.DefaultParams;
StimObj.DefaultParams.PawIndPositions = TargetParams.PawIndPositions * 0.96;
StimObj.DefaultParams.BranchDistDeg = TargetParams.BranchDistDeg * 0.96;
StimObj.DefaultParams.CurveTargetDistDeg = TargetParams.CurveTargetDistDeg * 0.96;

% Easiest settings
% gap = 1.3;
% StimObj.DefaultParams.Gap1_deg = [0 gap];

% Easy settings
gap = 1.3;
StimObj.DefaultParams.Gap1_deg = [0 gap*0.5];


% Target settings
% gap = 1.0;
% StimObj.DefaultParams.Gap1_deg = [0 gap*0.5];

StimObj.DefaultParams.Gap2_deg = [0 StimObj.DefaultParams.BranchDistDeg] + gap;

unsaturatedColor = [0.2 0.2 0.2; 0.2 0.2 0.2; .3 .3 .3];
% satLevel = 0;
% satLevel = 0.075/12;
satLevel = 5/12;
StimObj.DefaultParams.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

StimObj.DefaultCtrlParams = StimObj.DefaultParams;
StimObj.DefaultCtrlParams.NumOfPawIndicators = 5;
    
curvetracing = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv', 'Curve tracing', 'GroupConnections', false);

%  curvecatch = CurveTracingCatchBlockTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecontrol = CurveTracingJoystickTask(StimObj.DefaultCtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT', 'TargetLoc');
fixation = FixationTask(StimObj.DefaultFixParams);

Stm(1).KeepSubjectBusyTask = curvecontrol;
Stm(1).RestingTask = fixation;
% Stm(1).KeepSubjectBusyTask = fixation;

Stm(1).tasksToCycle = [...
    repmat({curvetracing}, 1, 4*2) ... curve tracing
    % repmat({curvecontrol}, 1, 1*2) ... control
    % repmat({fixation}, 1, 1*2) ... fixation
    ... {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
Stm(1).task = Stm(1).RestingTask;
% Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;

Stm(1).curvetracing = curvetracing;
%Stm(1).curvecatch = curvecatch;
Stm(1).curvecontrol = curvecontrol;
Stm(1).fixation = fixation;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;