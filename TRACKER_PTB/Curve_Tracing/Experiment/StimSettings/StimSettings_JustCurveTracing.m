function StimSettings_JustCurveTracing

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters

% use non-blocked curvetracing
curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');

Stm(1).tasksToCycle = [...
    {curvetracing} ... curve tracing
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvetracing;
Stm(1).alternateWithRestingBlocks = false;


StimObj.Stm = Stm;