function ParSettings_CalibrateFixation

% ParSettings gives all parameters for the experiment in global Par
global Par

%% Load defaults ==========================================================
eval('ParSettings'); % loads the default parameters

Par.FixWinSize = [1.8 1.8]; % [W H] in deg
Par.WaitForFixation = false; % Used to be Par.RequireFixation
Par.RequireFixationForReward = false;
Par.EndTrialOnResponse = true; % Make responsive