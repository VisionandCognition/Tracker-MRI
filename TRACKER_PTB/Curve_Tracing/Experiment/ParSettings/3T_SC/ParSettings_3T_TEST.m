function ParSettings_EDDY_3T_TEST

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

%% Load defaults ==========================================================
eval('ParSettings'); % loads the default parameters
Stm = StimObj.Stm;

Par.FixWinSize = [3 3]; % [W H] in deg
Stm(1).FixWinSizeDeg = Par.FixWinSize(1);

Par.FixWdDeg = Par.FixWinSize(1);
Par.FixHtDeg = Par.FixWinSize(2);

%% Setup ==================================================================
% Spinoza_Mock / Spinoza_3T / NIN
if strcmp(Par.ScreenChoice,'3T')
    Par.SetUp = 'Spinoza_3T';
elseif strcmp(Par.ScreenChoice,'Mock')
    Par.SetUp = 'Spinoza_MOCK';
end

%% Triggering =============================================================
Par.TR = 2.5; % Not important during training
Par.MRITriggeredStart = false;
Par.MRITrigger_OnlyOnce = true;

% parameters for interfacing with ISCAN
Par.EyeRecAutoTrigger = false;

%% Logging ================================================================
Par.PlotPerformance = false;

%% Reward scheme ==========================================================
% Require hands in the box (reduces movement?)
% Needed for initiation of tracker since it's in the gui now
Par.StimNeedsHandInBox=false;
Par.FixNeedsHandInBox=false;

Par.StartTrialDespiteLeverPositions = true;

Par.RequireHandsIn = false;
%Par.RequireHandsIn = false;  % <--- TEMPORARY!!!
