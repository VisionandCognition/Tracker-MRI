function runstim(Hnd)
% Updated 2017 Jonathan Williford

global Par   %global parameters
global StimObj %stimulus objects
global Log

% Just some sanity checks to make sure there aren't duplicate m files
assert(size(which('GiveRewardAuto','-all'),1)==1)
assert(size(which('CheckFixation','-all'),1)==1)
assert(size(which('CheckTracker','-all'),1)==1)
assert(size(which('CheckKeys','-all'),1)==1)

Par.RESP_NONE = 0;
Par.RESP_CORRECT = 1;
Par.RESP_FALSE = 2;
Par.RESP_MISS = 3;
Par.RESP_EARLY = 4;
Par.RESP_BREAK_FIX = 5;

RespText = {'Correct', 'False', 'Miss', 'Early', 'Fix. break'};

%% THIS SWITCH ALLOW TESTING THE RUNSTIM WITHOUT DASCARD & TRACKER ========
% if hasrealdas exists and says that there is no das card, then don't
%   run without the DAS...
Par.TestRunstimWithoutDAS = exist('hasrealdas', 'file') && ~hasrealdas();
%==========================================================================
for DoThisOnlyForTestingWithoutDAS=1
    if Par.TestRunstimWithoutDAS
        %  #------ Not tested - not expected to work ------#
        [~, basename, ext] = fileparts(pwd);
        if strcmp([basename ext], 'Experiment')
            % if not exited cleanly
        	cd ..;
        end
        cd engine;
        ptbInit % initialize PTB
        cd ..; cd Experiment;
        Par.scr=Screen('screens');
        Par.ScrNr=max(Par.scr); % use the screen with the highest #

        [Par.window, Par.wrect] = Screen('OpenWindow', Par.window, 0,...
                [0 0 1920 1080], [], 2, ... rect, pixelSize, numberOfBuffers
                [], [], [], ... stereomode, multisample, imagingmode
                kPsychGUIWindow); % specialFlags
            
            
        blend = Screen('BlendFunction', Par.window);
        if strcmp(blend, GL_ONE) || strcmp(blend, GL_ZERO)
            % attempting to get around strange bug with Matlab 2016B Linux
            Screen('BlendFunction', Par.window,...
                GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
            blend = Screen('BlendFunction', Par.window);
            if strcmp(blend, GL_ONE) || strcmp(blend, GL_ZERO)
                smo = 0;
            end
        end
            
        % Reduce PTB3 verbosity
        oldLevel = Screen('Preference', 'Verbosity', 0); %#ok<*NASGU>
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference','SkipSyncTests',1);
        
        %Do some basic initializing
        AssertOpenGL;
        KbName('UnifyKeyNames');
        
        %Set ParFile and Stimfile
        Par.PARSETFILE = 'ParSettings';
        Par.STIMSETFILE = 'StimSettings';
    end
end
clc;

% re-run parameter-file to update stim-settings without restarting Tracker
%ParSettings; % this is the old way of hardcoding a ParSettings file
eval(Par.PARSETFILE); % this takes the ParSettings file chosen via the context menu

Stm = StimObj.Stm;

% Flip the proper background on screen
Screen('FillRect',Par.window, Par.BG .* Par.ScrWhite);
Par.lft=Screen('Flip', Par.window);
Par.ExpStart = NaN; % experiment not yet "started"

Log.events = EventLog;
%% Stimulus preparation ===================================================
Stm(1).tasksUnique = {Stm(1).RestingTask};
if isfield(Stm(1), 'KeepSubjectBusyTask') && ...
        Stm(1).RestingTask ~= Stm(1).KeepSubjectBusyTask
    Stm(1).tasksUnique{end+1} = Stm(1).KeepSubjectBusyTask;
end
for i = 1:length(Stm(1).tasksToCycle)
    unique = true;
    for j = 1:length(Stm(1).tasksUnique)
        if Stm(1).tasksToCycle{i} == Stm(1).tasksUnique{j}
            unique = false;
            break
        end
    end
    if unique
        Stm(1).tasksUnique{end+1} = Stm(1).tasksToCycle{i};
    end
end
for i = 1:length(Stm(1).tasksUnique)
    Stm(1).tasksUnique{i}.updateState('PREPARE_STIM', Par.lft);
end

%Stm(1).task.updateState('INIT_EXPERIMENT', Par.lft);
%% Code Control Preparation ===============================================
for CodeControl=1 %allow code folding
    % Some intitialization of control parameters
    Par.ESC = false; %escape has not been pressed
    Par.endExperiment  = false;
    Log.MRI.TriggerReceived = false;
    Log.MRI.TriggerTime = [];
    Log.ManualReward = false;
    Log.ManualRewardTime = [];
    Log.TotalReward=0;
    Log.TCMFR = [];
    Log.numMiniBlocks = 0;
    
    % Turn off fixation for first block (so that it can be calibrated)
    OldPar.WaitForFixation = Par.WaitForFixation;
    OldPar.RequireFixationForReward = Par.RequireFixationForReward;
    Par.RequireFixationForReward = false;
    Par.WaitForFixation = false;
    Log.events.add_entry(GetSecs, 'NA', 'FixationRequirement', 'Stop');

    % Flip the proper background on screen
    Screen('FillRect',Par.window, Par.BG .* Par.ScrWhite);
    Par.lft=Screen('Flip', Par.window);
    Par.lft=Screen('Flip', Par.window, Par.lft+1);
    
    Par.ExpStart = Par.lft;
    Log.events.begin_experiment(Par.ExpStart);

    % Initial stimulus position is 1
    Par.PosNr=1;
    Par.PrevPosNr=1;

    % Initialize KeyLogging
    Par.KeyIsDown=false;
    Par.KeyWasDown=false;
    Par.KeyDetectedInTrackerWindow=false;

    % Initialize photosensor manual response
    Par.BeamLIsBlocked=false;  Par.BeamRIsBlocked=false;
    Par.BeamLWasBlocked=false; Par.BeamRWasBlocked=false;
    Par.ForpRespLeft=false;  Par.ForpRespRight=false;
    
    Par.NewResponse = false; % updated every CheckManual
    Par.TrialResponse = false; % updated with NewResponse when not false
    Par.GoNewTrial = false;

    % Initialize control parameters
    Par.SwitchPos = false;
    Par.ToggleCyclePos = true; % overrules the Stim(1)setting; toggles with 'p'
    Par.ManualReward = false;
    Par.PosReset = false;
    Par.BreakTrial = false;
    Par.GiveRewardAmount = 0;
    Par.GiveRewardAmount_onResponseRelease = 0;

    % Trial Logging
    Par.CurrResponse = Par.RESP_NONE;
    
    Par.Response = [0 0 0 0 0]; % counts [correct false-hit miss early fix.break]

    Par.FirstInitDone=false;
    Par.CheckFixIn=false;
    Par.CheckFixOut=false;
    Par.CheckTarget=false;
    Par.RewardRunning=false;
    
    EyeRecMsgShown=false;
    
    Log.Eye =[];
    Par.CurrEyePos = [];
    Par.CurrEyeZoom = [];
    Par.Verbosity = 2;
    Par.exitOnKeyWaitForMRITrigger = false;
end


% This control parameter needs to be outside the stimulus loop
FirstEyeRecSet=false;
if ~Par.TestRunstimWithoutDAS
    dasbit(0,1); %set eye-recording trigger to 1 (=stopped)
    %reset reward slider based on ParSettings
    handles=guihandles(Par.hTracker);
    if numel(Par.RewardTime)==1
        set(handles.Lbl_Rwtime, 'String', num2str(Par.RewardTime, 5))
        set(handles.slider1, 'Value', Par.RewardTime)
    else
        set(handles.Lbl_Rwtime, 'String', num2str(Par.RewardTime(1,2), 5))
        set(handles.slider1, 'Value', Par.RewardTime(1,2))
    end
end

%get the monkeyname
FSTR = inputdlg('Specify primate''s name','Primate''s Name',1,{Par.MONKEY});
Par.MONKEY = FSTR{1};

% output stimsettings filename to cmd
fprintf(['Setup selected: ' Par.SetUp '\n']);
%fprintf(['Screen selected: ' Par.ScreenChoice '\n']);
fprintf(['TR: ' num2str(Par.TR) 's\n\n']);

DateString = datestr(clock,30);
DateString = DateString(1:end-2);
fprintf(['=== Running ' Par.STIMSETFILE ' for ' Par.MONKEY ' ===\n']);
fprintf(['Started at ' DateString '\n']);

suggestedTdaFilename = [Par.MONKEY '_' DateString '.tda'];
fprintf(['Suggested filename: ' suggestedTdaFilename '\n']);

%% Eye-tracker recording =============================================
if Par.EyeRecAutoTrigger
    if ~FirstEyeRecSet
        SetEyeRecStatus(0); % send record off signal
        hmb=msgbox('Prepare the eye-tracker for recording','Eye-tracking');
        uiwait(hmb);
        FirstEyeRecSet=true;
        pause(1);
    end

    MoveOn=false;
    StartSignalSent=false;
    while ~MoveOn
        StartEyeRecCheck = GetSecs;
        while ~Par.EyeRecStatus && GetSecs < StartEyeRecCheck + 3 % check for 3 seconds
            CheckEyeRecStatus; % checks the current status of eye-recording
            if ~StartSignalSent
                SetEyeRecStatus(1);
                StartSignalSent=true;
            end
        end
        BreakTime = GetSecs;
        if Par.EyeRecStatus % recording
            StartedEyeRecTime=BreakTime;
            fprintf('Started recording eyetrace\n');
            MoveOn=true;
        else
            fprintf('not recording yet\n')
            SetEyeRecStatus(1); %trigger recording
        end
    end
end
    
while ~Par.FirstInitDone
    %set control window positions and dimensions
    if ~Par.TestRunstimWithoutDAS
        DefineEyeWin;
        refreshtracker(1); %for your control display
        SetWindowDas;      %for the dascard, initializes eye control windows
    end

    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers

    Par.CurrResponse = Par.RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial = false;
    Par.TaskSwitched = true;
    Par.LastFixInTime=0;
    Par.LastFixOutTime=0;
    Par.FixIn=false; %initially set to 'not fixating'
    Par.FirstInitDone=true;
    Par.FixInOutTime=[0 0];
    Log.StartBlock=Par.lft;
    Par.lft=Screen('Flip', Par.window);  %initial flip to sync up timing
    Log.events.screen_flip(Par.lft, 'NA');
    Par.nf=0;
    Par.LastRewardTime = GetSecs;
end

%% PRE-TRIGGER TASK =======================================================
%   ___                               _   
%  | _ )_  _ ____  _  __ __ _____ _ _| |__
%  | _ \ || (_-< || | \ V  V / _ \ '_| / /
%  |___/\_,_/__/\_, |  \_/\_/\___/_| |_\_\
%               |__/                     
%==========================================================================

fprintf('\n\n ------- Begin pre-trigger busy-tasks (press ''W'' key to wait for trigger) -------\n');
if isfield(Stm(1),'KeepSubjectBusyTask')
    Par.exitOnKeyWaitForMRITrigger = true;
    PreviousVerbosity = Par.Verbosity;
    Par.Verbosity = 0;
    args=struct;
    args.alternateWithRestingBlocks=false;
    args.maxTimeSecs = 600.0;
    CurveTracing_MainLoop(Hnd, {Stm(1).KeepSubjectBusyTask}, 100, args);
    
    Par.Verbosity = PreviousVerbosity;
    Par.ESC=false; % Reset escape
    Par.exitOnKeyWaitForMRITrigger = false;
end


%% Wait for MRI trigger =============================================
Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
Par.lft=Screen('Flip', Par.window);
Log.events.screen_flip(Par.lft, 'NA');
if Par.MRITriggeredStart
    Par.WaitingForTriggerTime = GetSecs;
    Log.events.add_entry(Par.WaitingForTriggerTime, 'NA', 'MRI_Trigger', 'Waiting');
    fprintf('Waiting for MRI trigger (or press ''T'' on keyboard)\n');
    while ~Log.MRI.TriggerReceived
        CheckKeys;
    end
    received_time = Log.MRI.TriggerTime(end);
    Log.events.add_entry(Par.WaitingForTriggerTime, 'NA', ...
        'MRI_Trigger_Received', num2str(received_time-Par.WaitingForTriggerTime));
    fprintf(['MRI trigger received after ' ...
        num2str(received_time-Par.WaitingForTriggerTime) ' s after waiting\n']);
end


%% Scanning warm-up presentations =========================================
% keep doing this until escape is pressed or stop is clicked
%  __      __                           
%  \ \    / /_ _ _ _ _ __ ___ _  _ _ __ 
%   \ \/\/ / _` | '_| '  \___| || | '_ \
%    \_/\_/\__,_|_| |_|_|_|   \_,_| .__/
%                                 |_|    http://patorjk.com/software/taag
%==========================================================================

fprintf('\n\n ---------------  Start warm-up --------- \n');

args=struct;
args.alternateWithRestingBlocks=false;

CurveTracing_MainLoop(Hnd, {Stm(1).RestingTask}, 2, args);

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
%  __  __       _         _                   
% |  \/  |     (_)       | |                  
% | \  / | __ _ _ _ __   | | ___   ___  _ __  
% | |\/| |/ _` | | '_ \  | |/ _ \ / _ \| '_ \ 
% | |  | | (_| | | | | | | | (_) | (_) | |_) |
% |_|  |_|\__,_|_|_| |_| |_|\___/ \___/| .__/ 
%                                      | |    
%                                      |_| http://patorjk.com/software/taag
%==========================================================================

% Return fixation to "required" (or whatever default was)
Par.WaitForFixation = OldPar.WaitForFixation;
Par.RequireFixationForReward = OldPar.RequireFixationForReward;
if Par.WaitForFixation
    Log.events.add_entry(GetSecs, Stm(1).task.name, 'FixationRequirement', 'Start');
end


% --------------- Main loop
fprintf('\n\n ---------------  Start Main tasks loop --------- \n');
args=struct;
args.alternateWithRestingBlocks=Stm(1).alternateWithRestingBlocks;

CurveTracing_MainLoop(Hnd, Stm(1).tasksToCycle, 300, args);

% = = =                                                               = = =
% =                           END MAIN LOOP                               =
% =                                                                       =
% =========================================================================

%% Scanning cool-down presentations =======================================
% keep doing this until escape is pressed or stop is clicked
%    ___          _        _                 
%   / __|___  ___| |___ __| |_____ __ ___ _  
%  | (__/ _ \/ _ \ |___/ _` / _ \ V  V / ' \ 
%   \___\___/\___/_|   \__,_\___/\_/\_/|_||_|    http://patorjk.com/software/taag
%==========================================================================

fprintf('\n\n ---------------  Start cool-down --------- \n');

args=struct;
args.alternateWithRestingBlocks=false;
args.maxTimeSecs = 8.0;

Par.ESC=false; % Reset escape
CurveTracing_MainLoop(Hnd, {Stm(1).RestingTask}, 2, args);

% Clean up and Save Log ===================================================
%   ____ _                                
%  / ___| | ___  __ _ _ __    _   _ _ __  
% | |   | |/ _ \/ _` | '_ \  | | | | '_ \ 
% | |___| |  __/ (_| | | | | | |_| | |_) |
%  \____|_|\___|\__,_|_| |_|  \__,_| .__/ 
%                                  |_|    
%==========================================================================
for CleanUp=1 % code folding
    fprintf('Experiment ended. Cleaning up and saving logs.\n');
    % end eye recording if necessary
    if Par.EyeRecAutoTrigger && ~EyeRecMsgShown
        cn=0;
        while Par.EyeRecStatus == 0 && cn < 100
            CheckEyeRecStatus; % checks the current status of eye-recording
            cn=cn+1;
        end
        if Par.EyeRecStatus % recording
            while Par.EyeRecStatus
                SetEyeRecStatus(0);
                pause(1)
                CheckEyeRecStatus
            end
            fprintf('\nStopped eye-recording. Save the file or add more runs.\n');
            %fprintf(['Suggested filename: ' Par.MONKEY '_' DateString '.tda\n']);
        else % not recording
            fprintf('\n>> Alert! Could not find a running eye-recording!\n');
        end
        EyeRecMsgShown=true;
    end
    fprintf(['Suggested filename: ' suggestedTdaFilename '\n']);
    if strcmp(Par.SetUp,'Spinoza_3T')
        clipboard('copy', suggestedTdaFilename)
    end
    
    % Empty the screen
    Screen('FillRect',Par.window,Stm(1).task.param('BGColor').*Par.ScrWhite);
    Par.lft = Screen('Flip', Par.window, Par.lft+.9*Par.fliptimeSec);
    if ~Par.TestRunstimWithoutDAS
        dasjuice(0); %stop reward if its running
    end
    
    % Add the time of writing the log - to avoid accidental overwrites
    % I'm not sure how accidental overwrite has happened - but it did once.
    % It has something to do with doing something in the MRI trigger
    % waiting period (such as starting the experiment again).
    TimeWriteStr = datestr(clock,'HHMM.SS');

    % save stuff
    if ~Par.TestRunstimWithoutDAS
        FileName=['Log_' Par.SetUp '_' Par.MONKEY '_' Par.STIMSETFILE '_' ...
            DateString];
    else
        FileName=['Log_NODAS_' Par.SetUp '_' Par.MONKEY '_' Par.STIMSETFILE '_' ...
            DateString];
    end
    warning off; %#ok<WNOFF>
    
    logPath = getenv('TRACKER_LOGS');
    %[~, currDir, ~] = fileparts(pwd);
    %logPath = fullfile(logPath, Par.ProjectLogDir, [Par.SetUp '_' Par.MONKEY '_' DateString(1:8)]);
    logPath = fullfile(logPath, Par.ProjectLogDir, ...
        [Par.SetUp '_' Par.MONKEY '_' DateString(1:8)], ...
        [Par.MONKEY '_' Par.ProjectLogDir, '_' Par.STIMSETFILE '_' Par.SetUp '_' DateString '-T' TimeWriteStr]);
    mkdir(logPath);
    filePath = fullfile(logPath, FileName);
    %if Par.TestRunstimWithoutDAS; cd ..;end
    
    %mkdir('Log');cd('Log');
    save(filePath,'Log','Par','StimObj');
    Log.events.write_csv([filePath '_eventlog.csv']);
    
    for i = 1:length(Stm(1).tasksUnique)
        Stm(1).tasksUnique{i}.write_trial_log_csv(filePath);
    end

    % Print / write human-readable summary of performance
    fprintf('\n');
    fout = fopen([filePath '_summary.txt'], 'w');
    for fid = [1 fout]
        fprintf(fid, 'Total counts\n------------\n\n');
        fprintf(fid, 'Correct: %d\n', Par.Response(Par.RESP_CORRECT));
        fprintf(fid, 'Incorrect: %d\n', Par.Response(Par.RESP_FALSE));
        fprintf(fid, 'Early response: %d\n', Par.Response(Par.RESP_EARLY));
        fprintf(fid, 'Late / no response: %d\n', Par.Response(Par.RESP_MISS));
        fprintf(fid, 'Fix. breaks: %d\n\n', Par.Response(Par.RESP_BREAK_FIX));
        totalResp = sum(Par.Response([Par.RESP_CORRECT Par.RESP_FALSE Par.RESP_EARLY]));
        fprintf(fid, 'Responses: %d\n\n', totalResp);
        
        fprintf(fid, 'Probabilities\n-------------\n\n');
        fprintf(fid, 'Correct: %d%%\n', round(Par.Response(Par.RESP_CORRECT)*100/totalResp));
        fprintf(fid, 'Incorrect: %d%%\n', round(Par.Response(Par.RESP_FALSE)*100/totalResp));
        fprintf(fid, 'Early response: %d%%\n', round(Par.Response(Par.RESP_EARLY)*100/totalResp));
        
    
        for i = 1:length(Stm(1).tasksUnique)
            fprintf(fid, '\n%s\n-------------\n\n', Stm(1).tasksUnique{i}.name());
            CHR = Stm(1).tasksUnique{i}.trackerWindowDisplay();
            fprintf(fid, '%s\n', CHR{:});
        end
    end
    fclose(fout);

    %if Par.TestRunstimWithoutDAS; cd Experiment;end
    warning on; %#ok<WNON>
    
    % if running without DAS close ptb windows
    %if Par.TestRunstimWithoutDAS
    %    Screen('closeall');
    %end
    fprintf('Done.\n');
    fprintf(['Suggested filename: ' suggestedTdaFilename '\n']);
end 
    
% ---------------------------------------------------------------------
%   ___                               _   
%  | _ )_  _ ____  _  __ __ _____ _ _| |__
%  | _ \ || (_-< || | \ V  V / _ \ '_| / /
%  |___/\_,_/__/\_, |  \_/\_/\___/_| |_\_\
%               |__/                         POST-EXPERIMENT TASK

if isfield(Stm(1),'KeepSubjectBusyTask')
    
    fprintf('\n\nStart Post-experiment keep-busy task.\n');
    
    PreviousVerbosity = Par.Verbosity;
    Par.Verbosity = 0;
    Par.ESC=false; % Reset escape
    args=struct;
    args.alternateWithRestingBlocks=false;
    CurveTracing_MainLoop(Hnd, {Stm(1).KeepSubjectBusyTask}, 10, args);
    
    Par.Verbosity = PreviousVerbosity;
end
fprintf('Post-experiment busy tasks finished.\n');
    %                     END POST-EXPERIMENT TASK
    % ---------------------------------------------------------------------



% check eye-tracker recording status
    function CheckEyeRecStatus
        daspause(5);
        ChanLevels=dasgetlevel;
        Par.CheckRecLevel=ChanLevels(Par.ConnectBox.EyeRecStat-2);
        %Par.CheckRecLevel
        % dasgetlevel starts reporting at channel 3, so subtract 2 from the channel you want (1 based)
        if strcmp(computer,'PCWIN64') && Par.CheckRecLevel < 48000 % 64bit das card
            Par.EyeRecStatus = 1;
        elseif strcmp(computer,'PCWIN') &&  Par.CheckRecLevel < 2750 % old das card
            Par.EyeRecStatus = 1;
        else
            Par.EyeRecStatus = 0;
        end
    end
% set eye-tracker recording status
    function SetEyeRecStatus(status)
        if status % switch on
            Par.EyeRecTriggerLevel=0;
        elseif ~status % switch off
            Par.EyeRecTriggerLevel=1;
        end
        tEyeRecSet = GetSecs;
        %Par.EyeRecTriggerLevel
        dasbit(0,Par.EyeRecTriggerLevel);
        %Log.nEvents=Log.nEvents+1;
        if Par.EyeRecTriggerLevel
            Log.events.add_entry(tEyeRecSet, 'NA', 'EyeRecOff');
            %Log.Events(Log.nEvents).type='EyeRecOff';
        else
            Log.events.add_entry(tEyeRecSet, 'NA', 'EyeRecOn');
            %Log.Events(Log.nEvents).type='EyeRecOn';
        end
    end
end

