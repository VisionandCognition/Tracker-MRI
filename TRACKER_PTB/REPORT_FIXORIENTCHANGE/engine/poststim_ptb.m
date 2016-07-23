global Par

Screen('CloseAll'); 
ListenChar();

if isfield(Par,'DasOn') && Par.DasOn == 1
    fprintf('\nClosing connection with the dascard...\n');
    while Par.DasOn
        dasclose(Par.Board);
        %cgshut
        Par.DasOn = 0;
    end
else
    fprintf('\nNo running das-connection detected\n');
end

% remove current folders from path
warning off;
rmpath(genpath(Par.ExpFolder));
warning on;

% Go to root folder
cd(Par.StartFolder);
close all hidden
%  clear global LPStat
clear all
%  close all

%clc;
fprintf('Tracker was closed without problems.\n');