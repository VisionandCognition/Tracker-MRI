function runstim(Hnd)
% Updated 2017 Jonathan Williford

global Par   %global parameters
global StimObj %stimulus objects
global Log

Par.RESP_NONE = 0;
Par.RESP_CORRECT = 1;
Par.RESP_FALSE = 2;
Par.RESP_MISS = 3;
Par.RESP_EARLY = 4;
Par.RESP_BREAK_FIX = 5;

RespText = {'Correct', 'False', 'Miss', 'Early', 'Fix. break'};

%% THIS SWITCH ALLOW TESTING THE RUNSTIM WITHOUT DASCARD & TRACKER ========
Par.TestRunstimWithoutDAS = ~hasrealdas();
%==========================================================================
for DoThisOnlyForTestingWithoutDAS=1
    if Par.TestRunstimWithoutDAS
        %  #------ Not tested - not expected to work ------#
        cd ..; cd Engine;
        ptbInit % initialize PTB
        cd ..; cd Experiment;
        Par.scr=Screen('screens');
        Par.ScrNr=max(Par.scr); % use the screen with the highest #
        if Par.ScrNr==0
            % part of the screen
            [Par.window, Par.wrect] = ...
                Screen('OpenWindow',Par.ScrNr,0,[0 0 1000 800],[],2);
            % fullscreen
            % [Par.window, Par.wrect] = Screen('OpenWindow',Par.ScrNr,0,[],[],2);
        else
            [Par.window, Par.wrect] = Screen('OpenWindow',Par.ScrNr,0,[],[],2);
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
lft=Screen('Flip', Par.window);
Par.ExpStart = NaN; % experiment not yet "started"

Log.events = EventLog;
%% Stimulus preparation ===================================================
Stm(1).tasksUnique = {Stm(1).RestingTask};
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
    Stm(1).tasksUnique{i}.updateState('PREPARE_STIM', lft);
end

Log.events.begin_experiment(lft)
%Stm(1).task.updateState('INIT_EXPERIMENT', lft);
%% Code Control Preparation ===============================================
for CodeControl=1 %allow code folding
    % Some intitialization of control parameters
    Par.ESC = false; %escape has not been pressed
    Par.endExperiment  = false;
    Par.numEscapePresses = 0;
    Par.WindDownScan = false;
    Par.WindDownStartTime = nan;
    Log.MRI.TriggerReceived = false;
    Log.MRI.TriggerTime = [];
    Log.ManualReward = false;
    Log.ManualRewardTime = [];
    Log.TotalReward=0;
    Log.TCMFR = [];
    Log.numMiniBlocks = 1;
    
    % Turn off fixation for first block (so that it can be calibrated)
    OldPar.WaitForFixation = Par.WaitForFixation;
    OldPar.RequireFixationForReward = Par.RequireFixationForReward;
    Par.RequireFixationForReward = false;
    Par.WaitForFixation = false;
    Log.events.add_entry(GetSecs, 'NA', 'FixationRequirement', 'Stop');

    % Flip the proper background on screen
    Screen('FillRect',Par.window, Par.BG .* Par.ScrWhite);
    lft=Screen('Flip', Par.window);
    lft=Screen('Flip', Par.window, lft+1);
    Par.ExpStart = lft;

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
    Par.NewResponse = false; % updated every CheckManual
    Par.TrialResponse = false; % updated with NewResponse when not false
    Par.GoNewTrial = false;

    % Initialize control parameters
    Par.SwitchPos = false;
    Par.ToggleNoisePatch = false;
    Par.ToggleCyclePos = true; % overrules the Stim(1)setting; toggles with 'p'
    Par.ManualReward = false;
    Par.PosReset = false;
    Par.BreakTrial = false;
    Par.GiveRewardAmount = 0;
    Par.GiveRewardAmount_onResponseRelease = 0;

    % Trial Logging
    Par.CurrResponse = Par.RESP_NONE;
    
    Par.Response = [0 0 0 0 0]; % counts [correct false-hit miss early fix.break]
    Par.RespTimes = [];

    Par.FirstInitDone=false;
    Par.CheckFixIn=false;
    Par.CheckFixOut=false;
    Par.CheckTarget=false;
    Par.RewardRunning=false;
    
    EyeRecMsgShown=false;
    
    Log.Eye =[];
    Par.CurrEyePos = [];
    Par.CurrEyeZoom = [];
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

%% Wait for MRI trigger =============================================
Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
lft=Screen('Flip', Par.window);
Log.events.screen_flip(lft, 'NA');
if Par.MRITriggeredStart
    Log.events.add_entry(GetSecs, 'NA', 'MRI_Trigger', 'Waiting');
    fprintf('Waiting for MRI trigger (or press ''t'' on keyboard)\n');
    while ~Log.MRI.TriggerReceived
        CheckKeys;
    end
    fprintf(['MRI trigger received after ' num2str(GetSecs-Par.ExpStart) ' s\n']);
end

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

while ~Par.ESC  %|| (Par.ESC && ~isfield(Stm(1), 'RestingTask')))
    
    if Stm(1).task.endOfBlock() % ------- Start new block?
        % Display information from previous task
        CHR = Stm(1).task.trackerWindowDisplay();
        fprintf('%s\n', CHR{:});
        
        Log.numMiniBlocks = Log.numMiniBlocks + 1;
        % Last block(s) should be resting blocks
        if Par.ESC || Par.WindDownScan % && isfield(Stm(1), 'RestingTask')
            % if the previous block was a resting block, don't need to add
            % another resting block
            if isnan(Par.WindDownStartTime) && Stm(1).task ~= Stm(1).RestingTask
                Par.WindDownStartTime = lft;
                Stm(1).taskCycleInd = NaN;
                Stm(1).task = Stm(1).RestingTask;
            else
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'EndExperiment', 'Rested');
                Par.ESC = true;
                Par.endExperiment = true;
                break;
            end
        else
            if Log.numMiniBlocks == 2
                Stm(1).taskCycleInd = NaN;
                Stm(1).task = Stm(1).RestingTask;
                
                Par.WaitForFixation = OldPar.WaitForFixation;
                Par.RequireFixationForReward = OldPar.RequireFixationForReward;
                if Par.WaitForFixation
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'FixationRequirement', 'Start');
                end
            elseif Stm(1).alternateWithRestingBlocks && ...
                    Stm(1).task ~= Stm(1).RestingTask
                Stm(1).taskCycleInd = NaN;
                Stm(1).task = Stm(1).RestingTask;
            else
                Stm(1).taskCycleInd = randi(length(Stm(1).tasksToCycle));
                Stm(1).task = Stm(1).tasksToCycle{Stm(1).taskCycleInd};
            end
        end
        fprintf('-- Start mini-block %d: %s --\n', Log.numMiniBlocks, Stm(1).task.name);
        Log.events.add_entry(lft, Stm(1).task.name, 'NewMiniBlock', num2str(Log.numMiniBlocks));
    end
    
    % ----------------------------------------------- Start new trial -----
    Stm(1).task.updateState('INIT_TRIAL', lft);
    
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
        Log.StartBlock=lft;
        lft=Screen('Flip', Par.window);  %initial flip to sync up timing
        Log.events.screen_flip(lft, 'NA');
        nf=0;
        Par.LastRewardTime = GetSecs;
    end
       
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.CurrResponse = Par.RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    Par.TrialResponse = false;
    
    % Eye Window preparation ----------------------------------------------
    for PrepareEyeWin=1
        DefineEyeWin;
    end
    if ~Par.TestRunstimWithoutDAS
        dasreset( 0 );
    end
    
    % Check eye fixation --------------------------------------------------
    CheckFixation;
    
    % Wait for fixation ---------------------------------------------------
    Stm(1).task.updateState('PREFIXATION', lft);
    Par.FixStart=Inf;
    %fprintf('Start %s task\n', Stm(1).task.name);
    
    % ---------------------------------------------------------------------
    %
    %                       WITHIN-TRIAL LOOP
    %
    %     Go through all of the different states of the current trial
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    while ~Stm(1).task.endOfTrial() && ~Par.PosReset && ~Par.endExperiment && ~Par.BreakTrial
        
        CheckManual;
        Stm(1).task.checkResponses(GetSecs);
        CheckKeys;
        lft = Stm(1).task.drawStimuli(lft);
        
        %% log eye-info if required
        LogEyeInfo;
        
        CheckFixation;
        CheckTracker; % Get and plot eye position
        ChangeStimulus; % Change stimulus if required (e.g. fixation moved).
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        % Check eye position
        %CheckTracker(); % just for plotting
        CheckFixation;
        
        % give automated reward
        if Par.GiveRewardAmount > 0 % Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    %
    %                     END WITHIN-TRIAL LOOP
    %
    % ---------------------------------------------------------------------
    
    % no response or fix break during switch = miss
    % ~Par.ResponseGiven && ~Par.FalseResponseGiven && ...
    if Par.CurrResponse == Par.RESP_NONE            
        Par.CurrResponse = Par.RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
    end
    
    % Performance info on screen
    for PerformanceOnCMD=1
        if Par.PosReset
            Log.events.add_entry(lft, Stm(1).task.name, 'PosReset');
            
            % reset
            Par.Trlcount(1) = 0;
            Par.CorrStreakcount(1)=0;
            Par.PosReset=false; %start new trial when switching position
        else
            Log.events.add_entry(lft, Stm(1).task.name, 'TrialCompleted');
        end
    end
    
    % Update Tracker window
    if ~Par.TestRunstimWithoutDAS
        SCNT = Stm(1).task.trackerWindowDisplay();
        set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
        % Give noise-on-eye-channel info
        SD = dasgetnoise();
        SD = SD./Par.PixPerDeg;
        set(Hnd(2), 'String', SD )
    end
end

% = = =                                                               = = =
% =                           END MAIN LOOP                               =
% =                                                                       =
% =========================================================================

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
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    if ~Par.TestRunstimWithoutDAS
        dasjuice(0); %stop reward if its running
    end
    
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
    logPath = fullfile(logPath, Par.ProjectLogDir, [Par.SetUp '_' Par.MONKEY '_' DateString(1:8)]);
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

    if Par.TestRunstimWithoutDAS; cd Experiment;end
    warning on; %#ok<WNON>
    
    % if running without DAS close ptb windows
    if Par.TestRunstimWithoutDAS
        Screen('closeall');
    end
    fprintf('Done.\n');
    fprintf(['Suggested filename: ' suggestedTdaFilename '\n']);
    
    
    % ---------------------------------------------------------------------
    %
    %                       POST-EXPERIMENT TASK
    %
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if isfield(Stm(1),'KeepSubjectBusyTask')
        Stm(1).task = Stm(1).KeepSubjectBusyTask;
        
        Stm(1).task.updateState('PREPARE_STIM', lft);
        Stm(1).task.updateState('INIT_TRIAL', lft);
        
        % Wait for fixation ---------------------------------------------------
        Stm(1).task.updateState('PREFIXATION', lft);
        Par.FixStart=Inf;
    
        while ~Stm(1).task.endOfTrial() && ~Par.PosReset && ~Par.endExperiment && ~Par.BreakTrial

            CheckManual;
            Stm(1).task.checkResponses(GetSecs);
            CheckKeys;
            lft = Stm(1).task.drawStimuli(lft);

            %% log eye-info if required
            % LogEyeInfo;

            CheckFixation;
            CheckTracker; % Get and plot eye position
            ChangeStimulus; % Change stimulus if required (e.g. fixation moved).

            % give manual reward
            if Par.ManualReward
                GiveRewardManual;
                Par.ManualReward=false;
            end

            % Check eye position
            %CheckTracker(); % just for plotting
            CheckFixation;

            % give automated reward
            if Par.GiveRewardAmount > 0 % Par.RespValid && ~Par.AutoRewardGiven
                GiveRewardAuto;
                Par.AutoRewardGiven = true;
            end
        end
    end
    %                     END POST-EXPERIMENT TASK
    % ---------------------------------------------------------------------
end

%% Standard functions called throughout the runstim =======================
% create fixation window around target
    function DefineEyeWin
        FIX = 0;  %this is the fixation window
        TALT = 1; %this is an alternative/erroneous target window --> not used
        TARG = 2; %this is the correct target window --> not used
        FixWinSizePix = Stm(1).task.param('FixWinSizePix');
        Par.WIN = [...
            Stm(1).task.taskParams.FixPositionsPix(Par.PosNr,:), ...
            FixWinSizePix, ...
            FixWinSizePix, FIX]';
        refreshtracker( 1) %clear tracker screen and set fixation and target windows
        SetWindowDas; %set das control thresholds using global parameters : Par
    end

% change stimulus features
    function ChangeStimulus
        % Change stimulus features if required
        % Position
        if Par.SwitchPos
            Par.PosReset=true;
            Par.PrevPosNr=Par.PosNr;
            switch Par.WhichPos
                case '1'
                    Par.PosNr = 1;
                case '2'
                    Par.PosNr = 2;
                case '3'
                    Par.PosNr = 3;
                case '4'
                    Par.PosNr = 4;
                case '5'
                    Par.PosNr = 5;
                case 'Next'
                    Par.PosNr = Par.PosNr + 1;
                    if Par.PosNr > 5
                        Par.PosNr = Par.PosNr - 5;
                    end
                    %                 case 'Prev'
                    %                     Par.PosNr = Par.PosNr -1;
                    %                     if Par.PosNr < 1
                    %                         Par.PosNr = Par.PosNr + 5;
                    %                     end
            end
        end
        % Toggle noise patch
        if Par.ToggleNoisePatch
            if ~Par.DrawNoise
                Par.DrawNoise = true;
            else
                Par.DrawNoise = false;
            end
            Par.ToggleNoisePatch = false;
        end
    end
% check for key-presses
    function CheckKeys
        % check
        [Par.KeyIsDown,Par.KeyTime,KeyCode]=KbCheck; %#ok<*ASGLU>
        
        % interpret
        if Par.KeyIsDown && ~Par.KeyWasDown
            Key=KbName(KbName(KeyCode));
            if isscalar(KbName(KbName(KeyCode)))
                % The MRI trigger is the only key that can be sent outside
                % of tracker window
                if Key == Par.KeyTriggerMR
                    Log.MRI.TriggerReceived = true;
                    Log.MRI.TriggerTime = ...
                        [Log.MRI.TriggerTime; Par.KeyTime];
                    Log.events.add_entry(Par.KeyTime, 'NA', 'MRI_Trigger', 'Received');
                elseif Par.KeyDetectedInTrackerWindow % only in Tracker
                    switch Key
                        case Par.KeyEscape
                            if Par.numEscapePresses
                                Par.endExperiment = true;
                                Par.ESC = true;
                                fprintf('Ending scan.\n');
                                Log.events.add_entry(GetSecs, Stm(1).task.name, 'EndExperiment', 'EscapeKey');
                            else
                                fprintf('Winding down scan.\n');
                            end
                            Par.numEscapePresses = Par.numEscapePresses + 1;
                        case Par.KeySwitchToRestingTask
                            fprintf('Winding down scan.\n');
                            Par.WindDownScan = true;
                        case Par.KeyTriggerMR
                            % cannot be executed
                        case Par.KeyJuice
                            Par.ManualReward = true;
                            Log.ManualRewardTime = ...
                                [Log.ManualRewardTime; Par.KeyTime];
                        case Par.KeyBackNoise
                            Par.ToggleNoisePatch = true;
                        case Par.KeyCyclePos
                            if Par.ToggleCyclePos
                                Par.ToggleCyclePos = false;
                                fprintf('Toggle position cycling: OFF\n');
                            else
                                Par.ToggleCyclePos = true;
                                fprintf('Toggle position cycling: ON\n');
                            end
                        case Par.Key1
                            Par.SwitchPos = true;
                            Par.WhichPos = '1';
                        case Par.Key2
                            Par.SwitchPos = true;
                            Par.WhichPos = '2';
                        case Par.Key3
                            Par.SwitchPos = true;
                            Par.WhichPos = '3';
                        case Par.Key4
                            Par.SwitchPos = true;
                            Par.WhichPos = '4';
                        case Par.Key5
                            Par.SwitchPos = true;
                            Par.WhichPos = '5';
                        case Par.KeyNext
                            Par.SwitchPos = true;
                            Par.WhichPos = 'Next';
                            %                 case Par.KeyPrevious
                            %                     Par.SwitchPos = true;
                            %                     Par.WhichPos = 'Prev';
                        case Par.KeyRequireFixation
                            time = GetSecs;
                            if ~Par.RequireFixationForReward;
                                Par.RequireFixationForReward = true;
                                Par.WaitForFixation = true;
                                fprintf('Requiring fixation for reward.\n')
                                Log.events.add_entry(time, Stm(1).task.name, 'FixationRequirement', 'Start');
                            else
                                Par.RequireFixationForReward = false;
                                Par.WaitForFixation = false;
                                fprintf('Not requiring fixation for reward.\n')
                                Log.events.add_entry(time, Stm(1).task.name, 'FixationRequirement', 'Stop');
                            end
                    end
                end
                Par.KeyWasDown=true;
            end
        elseif Par.KeyIsDown && Par.KeyWasDown
            Par.SwitchPos = false;
        elseif ~Par.KeyIsDown && Par.KeyWasDown
            % key is released
            Par.KeyWasDown = false;
            Par.SwitchPos = false;
        end
        % reset to false
        Par.KeyDetectedInTrackerWindow=false;
    end
    function ResponsesReleased
        Par.GiveRewardAmount = Par.GiveRewardAmount + Par.GiveRewardAmount_onResponseRelease;
        Par.GiveRewardAmount_onResponseRelease = 0;
        GiveRewardAuto; % make sure reward immediately on release
    end
% check DAS for manual responses
    function CheckManual
        %check the incoming signal on DAS channel #3  (#4 base 1)
        % NB dasgetlevel only starts counting at the third channel (#2)
        ChanLevels=dasgetlevel;
        Log.RespSignal = ChanLevels(4-2);
        % dasgetlevel starts reporting at channel 3, so subtract 2 from the channel you want (1 based)
        
        % it's a slightly noisy signal
        % on 32 bit windows
        % 3770-3800 means uninterrupted light beam
        % 2080-2090 means interrupted light beam
        % to be safe: take the cut-off halfway @2750
        % values are different for 64 bit windows
        if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 % 64bit das card
            Par.BeamLIsBlocked = false;
            if Par.HandIsIn(1)
                Par.HandIsIn(1)=false;
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Left');
                if ~any(Par.HandIsIn)
                    ResponsesReleased();
                end
            end
        elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
            Par.BeamLIsBlocked = false;
            if Par.HandIsIn(1)
                Par.HandIsIn(1)=false;
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Left');
                if ~any(Par.HandIsIn)
                    ResponsesReleased();
                end
            end
        else
            Par.BeamLIsBlocked = true;
            if ~Par.HandIsIn(1)
                Par.HandIsIn(1)=true;
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Initiate', 'Left');
            end
        end
        
        if Stm(1).task.taskParams.NumBeams >= 2
            %check the incoming signal on DAS channel #4 (#5 base 1)
            % NB dasgetlevel only starts counting at the third channel (#2)
            % Right / Secondary beam
            Log.RespSignal = ChanLevels(5-2);
            if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 % 64bit das card
                Par.BeamRIsBlocked = false;
                if Par.HandIsIn(2)
                    Par.HandIsIn(2)=false;
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Right');
                    if ~any(Par.HandIsIn)
                        ResponsesReleased();
                    end
                end
            elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
                Par.BeamRIsBlocked = false;
                if Par.HandIsIn(2)
                    Par.HandIsIn(2)=false;
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Right');
                    if ~any(Par.HandIsIn)
                        ResponsesReleased();
                    end
                end
            else
                Par.BeamRIsBlocked = true;
                if ~Par.HandIsIn(2)
                    Par.HandIsIn(2)=true;
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Initiate', 'Right');
                end
            end
        end
        
        Par.NewResponse = false;
        % interpret left side
        if Par.BeamLIsBlocked && ~Par.BeamLWasBlocked
            Par.NewResponse = 1;
            Par.BeamLWasBlocked = true;
        elseif ~Par.BeamLIsBlocked && Par.BeamLWasBlocked
            % key is released
            Par.BeamLWasBlocked = false;
        end
        
        % interpret right side
        if Par.BeamRIsBlocked && ~Par.BeamRWasBlocked
            Par.NewResponse = 2;
            Par.BeamRWasBlocked = true;
        elseif ~Par.BeamRIsBlocked && Par.BeamRWasBlocked
            % key is released
            Par.BeamRWasBlocked = false;
        end
        
        if Par.NewResponse
            Par.TrialResponse = Par.NewResponse;
        end
        
        Par.GoNewTrial = ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked;
    end
    function CheckFixation
        % Check if eye enters fixation window =============================
        if ~Par.FixIn %not fixating
            if ~Par.CheckFixIn && ~Par.TestRunstimWithoutDAS
                dasreset(0); % start testing for eyes moving into fix window
            end
            Par.CheckFixIn=true;
            Par.CheckFixOut=false;
            Par.CheckTarget=false;
            
            % Load retinotopic mapping stimuli - none to load
            LoadStimuli=false;
            
            % Check eye position
            fixChange = CheckTracker;
            
            if fixChange % eye in fix window (hit will never be 1 is tested without DAS)
                Par.FixIn=true;
                Par.LastFixInTime=GetSecs;
                Stm(1).task.fixation_in(Par.LastFixInTime);
                
                % Par.Trlcount=Par.Trlcount+1;
                refreshtracker(3);
            end
            if mod(nf,100)==0 && ~Par.TestRunstimWithoutDAS
                refreshtracker(1);
            end
        end
        % Check if eye leaves fixation window =============================
        if Par.FixIn %fixating
            if ~Par.CheckFixOut && ~Par.TestRunstimWithoutDAS
                dasreset(1); % start testing for eyes leaving fix window
            end
            Par.CheckFixIn=false;
            Par.CheckFixOut=true;
            Par.CheckTarget=false;
            
            % Check eye position
            % DasCheck
            fixChange = CheckTracker;
            
            if fixChange % eye out of fix window
                Par.FixIn=false;
                Par.LastFixOutTime=GetSecs;
                
                Stm(1).task.fixation_out(Par.LastFixOutTime);
                
                refreshtracker(1);
                
                Log.events.add_entry(Par.LastFixOutTime, Stm(1).task.name, 'Fixation', 'Out');
            end
        end
    end
% give automated reward
    function GiveRewardAuto
        assert(Par.GiveRewardAmount >= 0);
        if Par.GiveRewardAmount <= 0
            return
        end
        Par.RewardTimeCurrent = Par.GiveRewardAmount;
        Par.GiveRewardAmount = 0;
        
        if size(Par.Times.Targ,2)>1;
            rownr= find(Par.Times.Targ(:,1)<Par.CorrStreakcount(2),1,'last');
            Par.Times.TargCurrent=Par.Times.Targ(rownr,2);
        else
            Par.Times.TargCurrent=Par.Times.Targ;
        end
        
        % Give the reward
        StartReward=GetSecs;
        if strcmp(computer,'PCWIN64')
            dasjuice(10); % 64bit das card
        else
            dasjuice(5) %old card dasjuice(5)
        end
        
        % Play back a sound
        if Par.RewardSound
            RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
            RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
            sound(RewY,Par.RewSndPar(1));
        end
        %stop the reward
        StopReward=false;
        while ~StopReward
            if GetSecs >= StartReward+Par.RewardTimeCurrent
                dasjuice(0);
                StopReward = true;
                Log.TotalReward = Log.TotalReward+Par.RewardTimeCurrent;
            end
        end
        Par.LastRewardTime = StartReward;
        Log.events.add_entry(StartReward, Stm(1).task.name, 'Reward', 'Auto');
        Log.events.add_entry(StartReward, Stm(1).task.name, 'TaskReward', num2str(Par.RewardTimeCurrent));
    end
% give manual reward
    function GiveRewardManual
        Par.RewardTimeCurrent = Par.RewardTimeManual;
        % Give the reward
        StartReward=GetSecs;
        if strcmp(computer,'PCWIN64')
            dasjuice(10); % 64bit das card
        else
            dasjuice(5) %old card dasjuice(5)
        end
        
        % Play back a sound
        if Par.RewardSound
            RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
            RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
            sound(RewY,Par.RewSndPar(1));
        end
        %stop the reward
        StopReward=false;
        while ~StopReward
            if GetSecs >= StartReward+Par.RewardTimeCurrent
                dasjuice(0);
                StopReward = true;
                Log.TotalReward = Log.TotalReward+Par.RewardTimeCurrent;
            end
        end
        Par.LastRewardTime = StartReward;
        %Log.events.add_entry(StartReward, Stm(1).task.name, 'Reward', 'Manual');
        Log.events.add_entry(StartReward, Stm(1).task.name, 'ManualReward', num2str(Par.RewardTimeCurrent));
    end
% check and update eye info in tracker window
    function fixChange = CheckTracker
        if Par.TestRunstimWithoutDAS
            fixChange = false;
        else
            dasrun(5);
            [fixChange, ~] = DasCheck;
            fixChange = fixChange ~= 0;
        end
    end
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

% log eye info
    function LogEyeInfo
        % if nothing changes in calibration
        % only log position at 5 Hz
        if size(Log.Eye,2)==0 || ...
                (sum(Par.ScaleOff-Log.Eye(end).ScaleOff) ~= 0 || ...
                (GetSecs-Par.ExpStart) - Log.Eye(end).t > 1/5)
            
            eye_i = size(Log.Eye,2)+1;
            Log.Eye(eye_i).t = GetSecs-Par.ExpStart;
            Log.Eye(eye_i).CurrEyePos = Par.CurrEyePos;
            Log.Eye(eye_i).CurrEyeZoom = Par.ZOOM;
            Log.Eye(eye_i).ScaleOff = Par.ScaleOff;
        end
    end

end
