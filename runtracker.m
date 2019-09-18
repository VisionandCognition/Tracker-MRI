function runtracker
global Par

%clear and welcome message
clc; fprintf('Starting Tracker. Please have some patience...\n');

%what matlab version
MatlabVersion = version;
if str2double([MatlabVersion(1) MatlabVersion(3)]) == 95 % R2018
    Par.ML = 2018;
elseif str2double([MatlabVersion(1) MatlabVersion(3)]) == 84 % R2014 
    Par.ML = 2014;
else % before R2014b
    Par.ML = 2013;
end
            
% Ask to select screen and configure accordingly
% BOLD screen at 3T needs to be flipped
% PTB will take care of this
Par.ScreenChoice = questdlg('Which setup (3T/Mock/NIN)?', 'Select Setup',...
    '3T','Mock','NIN','Mock');

% remember the startfolder
Par.StartFolder = cd;

% add scripts shared between projects
addpath(genpath(fullfile(pwd,'SharedScripts'))); 

% Add the log-folder as an environment variable
if ispc % windows
    setenv('TRACKER_LOGS', 'C:\Users\NINuser\Documents\Logs');
else % unix
    setenv('TRACKER_LOGS', fullfile(getenv('HOME'),'Desktop','Logs'));
end
[~,~,~] = mkdir(getenv('TRACKER_LOGS'));

% Select our experiment folder
cd TRACKER_PTB
Par.ExpFolder = uigetdir(pwd,'Choose your experiment root-folder (contains Engine & Experiment folders)');

if Par.ExpFolder
    % Add stuff to the path
    addpath(genpath(Par.ExpFolder));
    % Go to folder
    cd(Par.ExpFolder);
    % Run tracker
    Par.hTracker = tracker_CK;
else
    fprintf('You did not choose a valid Experiment folder. Exiting...\n')
end
