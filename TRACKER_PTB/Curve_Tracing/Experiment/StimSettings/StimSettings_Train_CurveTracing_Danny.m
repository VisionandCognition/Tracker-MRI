global StimObj

%% Load defaults ==========================================================
% The *parameters* for the classes are saved to StimSettings__Defaults__.
% The order of the blocks are defined below.
eval('StimSettings__DefaultsDanny__'); % loads the default parameters
Stm = StimObj.Stm;

%% THESE SETTINGS OVERWRITE DEFAULTS FOR TRAINING PURPOSES ===>>>>>>>>>====
% PawIndAlpha = [ PreSwitchAlpha target 1 target 2 ... ; 
%                   PostSwitchAlpha target 1 target 2 ... ]
% TOP & BOTTOM
StimObj.DefaultParams.CurveAlpha =  [1 1 1 1 1; ...
                                     1 1 1 1 1]; % UL DL UR DR CENTER
StimObj.DefaultParams.PawIndAlpha = [1 1 1 1 1; ...
                                     1 1 1 1 1]; % UL DL UR DR CENTER
%StimObj.DefaultParams.PawIndAlpha = [0.80 0.80 0.80 0.80 1; ...
                                    % 0.80 0.80 0.80 0.80 1]; % UL DL UR DR CENTER
                                
% TOP
%StimObj.DefaultParams.CurveAlpha =  [1 .1 1 .1 1; ...
%                                     1 .1 1 .1 1]; % UL DL UR DR CENTER
%StimObj.DefaultParams.PawIndAlpha = [.1 .45 .1 .45 1; ...
%                                     .1 .45 .1 .45 1]; % UL DL UR DR CENTER

% BOTTOM
%StimObj.DefaultParams.CurveAlpha =  [.1 1 .1 1 1; ...
%                                     .1 1 .1 1 1]; % UL DL UR DR CENTER
%StimObj.DefaultParams.PawIndAlpha = [.45 .1 .45 .1 1; ...
%                                     .45 .1 .45 .1 1]; % UL DL UR DR CENTER                                     


StimObj.DefaultParams.CurveAnglesAtFP = ...
    [ 180 180 0 0 ]; % UL DL UR DR

% === Overwrite gaps and branching from defaults stimsettings here ===
% Switched to using the defualts (same as Eddy) on 21-09-2018

% For reference:
% Eddy:                                 Danny before 21-09-2018:
% BranchDistDeg = 1.5;                  1.2
% CurveTargetDistDeg = 1.8;             1.5
% Gap1_deg = [0 0.5]                    [0 0.5]
% Gap2_deg = [0 BranchDistDeg] + 1      [0 BranchDistDeg] + 0.8

%StimObj.DefaultParams.BranchDistDeg = 1.2;%1.2;
%StimObj.DefaultParams.CurveTargetDistDeg = 1.5;
%gap = .5; secondgap = 0.8;
%StimObj.DefaultParams.Gap1_deg = [0 gap];
%StimObj.DefaultParams.Gap2_deg = [0 StimObj.DefaultParams.BranchDistDeg] + secondgap;
% ===

% -------------------------------------------------------------------------

% unsaturatedColor = [0.2 0.2 0.2; 0.2 0.2 0.2; .3 .3 .3]; % different shapes
unsaturatedColor = [0.3 0.3 0.3; 0.3 0.3 0.3; ambigCir ambigCir ambigCir];

% satLevel = 0;
% satLevel = 0.075/12;
satLevel = 0;%6/12;
StimObj.DefaultParams.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;

StimObj.DefaultCtrlParams = StimObj.DefaultParams;
StimObj.DefaultCtrlParams.NumOfPawIndicators = 5;
    
curvetracing = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv', 'Curve tracing', 'GroupConnections', false);
%curvetracing = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask_TOP.csv', 'Curve tracing', 'GroupConnections', false);
%curvetracing = CurveTracingJoystickTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask_BOTTOM.csv', 'Curve tracing', 'GroupConnections', false);

busy = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask.csv', 'Keep Busy', 'GroupConnections', false);
%busy = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask_TOP.csv', 'Keep Busy', 'GroupConnections', false);
%busy = CurveTracingJoystickTask(Params, 'StimSettings/CurveTracingJoyStickTask_BOTTOM.csv', 'Keep Busy', 'GroupConnections', false);

%  curvecatch = CurveTracingCatchBlockTask(StimObj.DefaultParams, 'StimSettings/CurveTracingJoyStickTask.csv');
curvecontrol = CurveTracingJoystickTask(StimObj.DefaultCtrlParams, 'StimSettings/CurveTracingJoyStickTask-Control.csv', 'Control CT', 'TargetLoc');

%% THESE SETTINGS OVERWRITE DEFAULTS FOR TRAINING PURPOSES ===<<<<<<<<<====

fixation = FixationTask(StimObj.DefaultFixParams);

Stm(1).KeepSubjectBusyTask_PreScan = fixation;%busy;
Stm(1).KeepSubjectBusyTask = fixation;%busy;%curvecontrol;
% Stm(1).KeepSubjectBusyTask = fixation;
Stm(1).RestingTask = fixation;

Stm(1).tasksToCycle = [...
    repmat({curvetracing}, 1, 4*2) ... curve tracing
    % repmat({curvecontrol}, 1, 1*2) ... control
    % repmat({fixation}, 1, 1*2) ... fixation
    ... {curvecatch} ... catch trial
    ];
Stm(1).taskCycleInd = 1;
Stm(1).task = Stm(1).RestingTask;
% Stm(1).task = curvecontrol; % This task is good for fixation calibration
Stm(1).alternateWithRestingBlocks = false;

Stm(1).curvetracing = curvetracing;
%Stm(1).curvecatch = curvecatch;
Stm(1).curvecontrol = curvecontrol;
Stm(1).busy = busy;
Stm(1).fixation = fixation;

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;