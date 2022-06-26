function runtracker(tracker_version)
global Par

if nargin < 1
    Par.tracker_version = 'default';
else
    Par.tracker_version = tracker_version;
end

% announce that this is an mlapp utility
fprintf('Using GUIDE, which will no longer be supported\n')
Par.ui = 'guide';

%clear and welcome message
clc; fprintf('Starting Tracker. Please have some patience...\n');
 
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
    Par.hTracker = tracker_CK; % standard light version of tracker
    Par.hTracker_ax=findobj(Par.hTracker,'Tag','axes1'); 
    if strcmp(Par.tracker_version, 'tracker_dark')
        set(Par.hTracker_ax,'Color','k');
    end
else
    fprintf('You did not choose a valid Experiment folder. Exiting...\n')
end
