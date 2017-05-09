function StimSettings_Mock

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

Stm = StimObj.Stm;

%% Load defaults ==========================================================
eval('StimSettings'); % loads the default parameters

% Fixation ----------------------------------------------------------------
Params.FixWinSizeDeg = 2.5; % in deg

% Saturation
satLevel = 4/6;
Params.PawIndCol = satLevel * Params.PawIndCol + (1 - satLevel) * unsaturatedColor;