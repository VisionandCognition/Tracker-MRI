function StimSettings_CalibrateFixation

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters



Stm(1).tasksToCycle = [...
    {curvetracing} ... curve tracing
    repmat({curvecontrol}, 1, 2) ... control
    {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = Stm(1).RestingTask;
Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;


StimObj.Stm = Stm;