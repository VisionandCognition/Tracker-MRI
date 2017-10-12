%StimSettings

% ParSettings gives all parameters for the experiment in global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings__Defaults__'); % loads the default parameters

Params = StimObj.DefaultParams;

unsaturatedColor = [0.2 0.2 0.2; 0.2 0.2 0.2; .3 .3 .3];
satLevel = 0.075/12;
Params.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

FixParams = Params;
FixParams.rewardMultiplier = 1.0; % 0.5;
FixParams.subtrialsInTrial = 8;
FixParams.fixationPeriod = 500;  % just for fixation task
FixParams.postfixPeriod = 0;  % just for fixation task

FixParams.rewardMultiplier = .12; % 0.5;
FixParams.BlockSize = 3; %round(3* 3500 / FixParams.fixationPeriod * FixParams.subtrialsInTrial);

% use non-blocked curvetracing
curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
Stm(1).KeepSubjectBusyTask = curvetracing;
fixation = FixationTask(FixParams);
Stm(1).RestingTask = fixation;

Stm(1).tasksToCycle = [...
    {curvetracing} ... curve tracing
    repmat({fixation}, 1, 1*2) ... fixation
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = checksides;
Stm(1).task = curvetracing;
Stm(1).alternateWithRestingBlocks = false;

StimObj.Stm = Stm;