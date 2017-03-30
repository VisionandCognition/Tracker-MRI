function StimSettings_CheckSides

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters


checksides = CurveTracingJoystickTask(CtrlParams, 'StimSettings/CurveTracingJoyStickTask-CheckSides.csv');

Stm(1).tasksToCycle = [...
    repmat({checksides}, 1, 97) ... check sides
    {curvetracing} ... curve tracing
    {curvecontrol} ... control
    {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;


StimObj.Stm = Stm;