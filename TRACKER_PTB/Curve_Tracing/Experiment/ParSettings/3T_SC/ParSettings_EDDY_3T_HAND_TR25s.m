function ParSettings_EDDY_3T_HAND_TR25s

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

%% Load defaults ==========================================================
eval('ParSettings'); % loads the default parameters

%% Setup ==================================================================
% Spinoza_Mock / Spinoza_3T / NIN
if strcmp(Par.ScreenChoice,'3T')
    Par.SetUp = 'Spinoza_3T';
elseif strcmp(Par.ScreenChoice,'Mock')
    Par.SetUp = 'Spinoza_MOCK';
end

%% Triggering =============================================================
Par.TR = 2.5; % Not important during training
Par.MRITriggeredStart = true;
Par.MRITrigger_OnlyOnce = true;

% parameters for interfacing with ISCAN
Par.EyeRecAutoTrigger = true;

%% Logging ================================================================
Par.PlotPerformance = true;