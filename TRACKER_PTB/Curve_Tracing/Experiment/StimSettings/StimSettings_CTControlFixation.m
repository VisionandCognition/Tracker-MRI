% ParSettings gives all parameters for the experiment in global Par
global StimObj

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters

Stm = StimObj.Stm;


Stm(1).tasksToCycle = [...
    repmat({Stm(1).curvecontrol}, 1, 2*2) ... control
    repmat({Stm(1).fixation}, 1, 1*2) ... fixation
    ];


Stm(1).taskCycleInd = 1;
%Stm(1).task = Stm(1).RestingTask;
Stm(1).task = Stm(1).RestingTask; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;