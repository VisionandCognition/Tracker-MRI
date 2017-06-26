global StimObj

%% Load defaults ==========================================================
% The *parameters* for the classes are saved to StimSettings__Defaults__.
% The order of the blocks are defined below.
eval('StimSettings__Defaults__'); % loads the default parameters

Stm = StimObj.Stm;
%curvetracing = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv');
Stm(1).KeepSubjectBusyTask = CurveTracingTitratedTask(StimObj.DefaultParams, ...
     'StimSettings/CurveTracingJoyStickTask.csv', ...
     'Keep busy');

curvetracing = CurveTracingBlockTitratedTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecatch = CurveTracingCatchBlockTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecontrol = CurveTracingTitratedTask(StimObj.DefaultCtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT');
%fixattion = FixationTask(StimObj.DefaultFixParams);
Stm(1).RestingTask = curvecontrol;

    %repmat({curvetracing}, 1, 4*4) ... curve tracing
    %repmat({curvecontrol}, 1, 1*4) ... control
    %repmat({fixation}, 1, 1*4) ... fixation
    %{curvecatch} ... catch trial
Stm(1).tasksToCycle = [...
    repmat({curvetracing}, 1, 4*2) ... curve tracing
    {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
%Stm(1).task = Stm(1).RestingTask;
Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = true;

Stm(1).curvetracing = curvetracing;
Stm(1).curvecatch = curvecatch;
Stm(1).curvecontrol = curvecontrol;
%Stm(1).fixation = fixation;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;