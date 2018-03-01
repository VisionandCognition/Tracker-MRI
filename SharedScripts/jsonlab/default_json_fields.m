function default_json_fields

% json defaults
global Par

%% REQUIRED FIELDS DEFAULTS ===============================================
Par.jf.Project      = 'DeafultProject'; % get from par << inlcude new
Par.jf.Method       = 'DefaultMethod'; % get from par << inlcude new

Par.jf.Protocol     = 'Default'    ; % get from par << inlcude new  
Par.jf.Dataset      = 'Default'    ; % get from par << inlcude new 
Par.jf.Date         = 'yyyymmdd'   ; % get from runstim
Par.jf.Subject      = 'DefaultMonkey'      ; % get from runstim

Par.jf.Researcher   = 'ChrisKlink'  ; % get from par << inlcude new
Par.jf.Setup        = 'SetUp'       ; % get from runstim
Par.jf.Group        = 'awake'       ; % get from par << inlcude new 
Par.jf.Stimulus     = 'StimName'    ; % get from runstim
% optional
Par.jf.LogFolder    = 'LogFolder'   ; % get from runstim

Par.jf.logfile_name = 'LogFileName.mat';   %name for your logfile