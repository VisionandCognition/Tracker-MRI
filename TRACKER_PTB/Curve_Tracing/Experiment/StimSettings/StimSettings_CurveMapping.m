function StimSettings_CurveMapping

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters

% use non-blocked curvetracing
curvemapping = CurveTracingTitratedTask(CtrlParams, 'StimSettings/CurveMapping.csv', 'Curve Mapping');
Stm(1).KeepSubjectBusyTask = curvemapping;

Stm(1).tasksToCycle = [...
    {curvemapping} ... curve mapping
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvetracing;
Stm(1).alternateWithRestingBlocks = false;




StimObj.Stm = Stm;