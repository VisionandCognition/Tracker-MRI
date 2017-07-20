function StimSettings_JustCurveTracing

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings__Defaults__'); % loads the default parameters

Params = StimObj.DefaultParams;

unsaturatedColor = [0.2 0.2 0.2; 0.2 0.2 0.2; .3 .3 .3];
satLevel = 1/12;
Params.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

% use non-blocked curvetracing
curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
Stm(1).KeepSubjectBusyTask = curvetracing;

Stm(1).tasksToCycle = [...
    {curvetracing} ... curve tracing
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvetracing;
Stm(1).alternateWithRestingBlocks = false;


StimObj.Stm = Stm;