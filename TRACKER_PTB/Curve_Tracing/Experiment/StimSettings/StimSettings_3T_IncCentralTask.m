global StimObj

%% Load defaults ==========================================================
% The *parameters* for the classes are saved to StimSettings__Defaults__.
% The order of the blocks are defined below.
eval('StimSettings__Defaults__'); % loads the default parameters

%% Change block size to 3
StimObj.DefaultParams.BlockSize = 3; % overwrite the default of 1 to use mini-blocks
StimObj.DefaultCtrlParams.BlockSize = StimObj.DefaultParams.BlockSize; % also miniblocks for central task
StimObj.DefaultCtrlParams.PawIndSizeDeg(5) = 0.5;

fprintf(['Mini-block size: ' num2str(StimObj.DefaultParams.BlockSize) '\n'] )


Stm = StimObj.Stm;

curvetracing = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');

%  curvecatch = CurveTracingCatchBlockTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');
busy = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv', 'Keep Busy', 'GroupConnections', false);
% busy = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv', 'Keep Busy', 'GroupConnections', false);
% busy = CurveTracingJoystickTask(StimObj.DefaultCtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT', 'TargetLoc');
fixation = FixationTask(StimObj.DefaultFixParams);
curvecontrol = CurveTracingTitratedTask(StimObj.DefaultCtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT');
%curvecontrol = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv');

Stm(1).KeepSubjectBusyTask_PreScan = busy;
Stm(1).KeepSubjectBusyTask = busy;
Stm(1).RestingTask = fixation;
% Stm(1).KeepSubjectBusyTask = fixation;

% tasksToCycle contain the tasks presented during scan
Stm(1).tasksToCycle = [...
	 repmat({curvetracing}, 1, 4) ... curve tracing
     repmat({curvecontrol}, 1, 1) ... central taskt
     %repmat({fixation}, 1, 1*2) ... fixation
    ... {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
Stm(1).task = Stm(1).RestingTask;
% Stm(1).task = busy; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;

Stm(1).curvetracing = curvetracing;
%Stm(1).curvecatch = curvecatch;
Stm(1).busy = busy;
Stm(1).fixation = fixation;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;