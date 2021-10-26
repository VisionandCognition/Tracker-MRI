% Reduce PTB3 verbosity
oldLevel = Screen('Preference', 'Verbosity', 0); %#ok<*NASGU>
Screen('Preference', 'VisualDebuglevel', 0);
Screen('Preference','SkipSyncTests',1);

%Do some basic initializing
AssertOpenGL;
KbName('UnifyKeyNames');

clc
fprintf('Started Tracker in PTB-3 mode\n');
%fprintf('(StimGui functionality won''t be available)\n');