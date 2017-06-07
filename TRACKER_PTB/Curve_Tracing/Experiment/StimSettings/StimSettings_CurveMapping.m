function StimSettings_CurveMapping

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters

% use non-blocked curvetracing
curvemapping = CurveTracingBlockByTitratedTask(CtrlParams, ...
    'StimSettings/CurveMapping_BothHemispheres.csv', ...
    'Curve Mapping', ...
    'CombinedStim');
Stm(1).KeepSubjectBusyTask = curvemapping;

Stm(1).tasksToCycle = [...
    {curvemapping} ... curve mapping
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvemapping;
Stm(1).alternateWithRestingBlocks = true;




StimObj.Stm = Stm;