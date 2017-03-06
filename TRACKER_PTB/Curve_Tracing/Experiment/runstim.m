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
TestRunstimWithoutDAS = false;
%==========================================================================
for DoThisOnlyForTestingWithoutDAS=1
    if TestRunstimWithoutDAS
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

Log.events = EventLog;
%% Stimulus preparation ===================================================
Stm(1).tasksUnique = {Stm(1).tasksToCycle{1}};
for i = 2:length(Stm(1).tasksToCycle)
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
    Log.MRI.TriggerReceived = false;
    Log.MRI.TriggerTime = [];
    Log.ManualReward = false;
    Log.ManualRewardTime = [];
    Log.TotalReward=0;
    Log.TCMFR = [];

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

    % Trial Logging
    Par.CurrResponse = Par.RESP_NONE;
    Par.Response = [0 0 0 0 0]; %[correct false-hit missed]
    Par.ResponsePos = [0 0 0 0 0]; %[correct false-hit missed]
    Par.RespTimes = [];
    Par.ManRewThisTrial=[];

    Par.FirstInitDone=false;
    Par.CheckFixIn=false;
    Par.CheckFixOut=false;
    Par.CheckTarget=false;
    Par.RewardRunning=false;
end

%% MRI triggered start
Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
lft=Screen('Flip', Par.window);
Log.events.screen_flip(lft, 'NA');
if Par.MRITriggeredStart
    Log.events.add_entry(GetSecs, 'NA', 'MRI_Trigger', 'Waiting');
    fprintf('Waiting for MRI trigger (or press ''t'' on keyboard)\n');
    while ~Log.MRI.TriggerReceived
        CheckKeys;
        %Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        %lft=Screen('Flip', Par.window);
    end
    fprintf(['MRI trigger received after ' num2str(GetSecs-Par.ExpStart) ' s\n']);
    Log.events.add_entry(GetSecs, 'NA', 'MRI_Trigger', 'Received');
end

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
% Structure: preswitch_period-switch_period/switched_duration-postswitch
while ~Par.ESC %===========================================================
    if Stm(1).task.endOfBlock()
        Stm(1).taskCycleInd = mod(Stm(1).taskCycleInd, length(Stm(1).tasksToCycle))+1;
        Stm(1).task = Stm(1).tasksToCycle{Stm(1).taskCycleInd};
    end
    Stm(1).task.updateState('INIT_TRIAL', lft);
    
    while ~Par.FirstInitDone
        %set control window positions and dimensions
        if ~TestRunstimWithoutDAS
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
    if ~TestRunstimWithoutDAS
        dasreset( 0 );
    end
    
    % Check eye fixation --------------------------------------------------
    CheckFixation;
    
    % Wait for fixation --------------------------------------------------
    Stm(1).task.updateState('PREFIXATION', lft);
    Par.FixStart=Inf;
    fprintf('Start %s task\n', Stm(1).task.name);
    
    % ---------------------------------------------------------------------
    % Go through all of the different states of the current trial
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    while ~Stm(1).task.endOfTrial() && ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        CheckManual;
        Stm(1).task.checkResponses(GetSecs);
        CheckKeys;
        lft = Stm(1).task.drawStimuli(lft);
        
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
    
    % no response or fix break during switch = miss
    % ~Par.ResponseGiven && ~Par.FalseResponseGiven && ...
    if Par.CurrResponse == Par.RESP_NONE            
        Par.CurrResponse = Par.RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
    end
    
    % Performance info on screen
    for PerformanceOnCMD=1
        if Par.PosReset
            Log.events.add_entry(lft, Stm(1).task.name, 'PosReset');
            
            % display & write stats for this position
            fprintf(['Pos ' num2str(Par.PrevPosNr) ': T=' ...
                num2str(Par.Trlcount(1)) ' C=' ...
                num2str(Par.ResponsePos(1)) ' M=' ...
                num2str(Par.ResponsePos(3)) ' F=' ...
                num2str(Par.ResponsePos(2)) ' (' ...
                num2str(round(100*Par.ResponsePos(1)/Par.Trlcount(1))) '%%)\n']);
            fprintf(['Tot: T=' ...
                num2str(Par.Trlcount(2)) ' C=' ...
                num2str(Par.Response(1)) ' M=' ...
                num2str(Par.Response(3)) ' F=' ...
                num2str(Par.Response(2)) ' (' ...
                num2str(round(100*Par.Response(1)/Par.Trlcount(2))) '%%)\n']);
            % reset
            Par.ResponsePos = 0*Par.ResponsePos;
            Par.Trlcount(1) = 0;
            Par.CorrStreakcount(1)=0;
            Par.PosReset=false; %start new trial when switching position
        else
            Log.events.add_entry(lft, Stm(1).task.name, 'TrialCompleted');
        end
        
        % Display total reward every x correct trials
        if Par.CurrResponse == Par.RESP_CORRECT && ...
                mod(Par.Response(Par.RESP_CORRECT),10) == 0 && ...
                Par.Response(Par.RESP_CORRECT) > 0
            
            fprintf(['\nTask: ' Stm(1).task.name '\n']);
        

            Log.TCMFR = [Log.TCMFR; ...
                Par.Trlcount(2) ...
                Par.Response(1) ...
                Par.Response(3) ...
                Par.Response(2) ...
                Log.TotalReward];
            fprintf(['Paw accuracy (block): ',...
                num2str( round(100 * ...
                Par.ResponsePos(Par.RESP_CORRECT)/...
                (Par.ResponsePos(Par.RESP_CORRECT) + ...
                Par.ResponsePos(Par.RESP_FALSE))))])
            fprintf(['%%\t (total): ',...
                num2str( round(100 * ...
                Par.Response(Par.RESP_CORRECT)/...
                (Par.Response(Par.RESP_CORRECT) + ...
                Par.Response(Par.RESP_FALSE))))...
                '%%\n\n'])

            % reset
            Par.ResponsePos = 0*Par.ResponsePos;
        end
    end
    
    % Update Tracker window
    if ~TestRunstimWithoutDAS
        %SCNT = {'TRIALS'};
%         SCNT(1) = { ['Corr:  ' num2str(Par.Response(Par.RESP_CORRECT)) ] };
%         SCNT(2) = { ['False: ' num2str(Par.Response(Par.RESP_FALSE)) ] };
%         SCNT(3) = { ['Miss:  ' num2str(...
%             Par.Response(Par.RESP_MISS)+Par.Response(Par.RESP_EARLY)+ ...
%             Par.Response(Par.RESP_BREAK_FIX)) ] };
%         SCNT(4) = { ['Total: ' num2str(Par.Trlcount(2)) ]};
%         if Par.CurrResponse > 0
%             SCNT(5) = { [RespText{Par.CurrResponse}]};
%         else
%             SCNT(5) = {''};
%         end
        SCNT = Stm(1).task.trackerWindowDisplay();
        set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
        % Give noise-on-eye-channel info
        SD = dasgetnoise();
        SD = SD./Par.PixPerDeg;
        set(Hnd(2), 'String', SD )
    end
end

%% Clean up and Save Log ==================================================
for CleanUp=1 % code folding
    % Empty the screen
    Screen('FillRect',Par.window,Stm(1).task.param('BGColor').*Par.ScrWhite);
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    if ~TestRunstimWithoutDAS
        dasjuice(0); %stop reward if its running
    end
    
    % save stuff
    if ~TestRunstimWithoutDAS
        FileName=['Log_' Par.STIMSETFILE '_' datestr(clock,30)];
    else
        FileName=['Log_NODAS_' Par.STIMSETFILE '_' datestr(clock,30)];
    end
    warning off; %#ok<WNOFF>
    
    logPath = getenv('TRACKER_LOGS');
    %[~, currDir, ~] = fileparts(pwd);
    logPath = fullfile(logPath, Par.ProjectLogDir);
    mkdir(logPath);
    filePath = fullfile(logPath, FileName);
    %if TestRunstimWithoutDAS; cd ..;end
    
    %mkdir('Log');cd('Log');
    save(filePath,'Log','Par','StimObj');
    Log.events.write_csv([filePath '.csv']);
    
    for i = 1:length(Stm(1).tasksUnique)
        Stm(1).tasksUnique{i}.write_trial_log_csv(filePath);
    end

    if TestRunstimWithoutDAS; cd Experiment;end
    warning on; %#ok<WNON>
    
    % if running without DAS close ptb windows
    if TestRunstimWithoutDAS
        Screen('closeall');
    end
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
                elseif Par.KeyDetectedInTrackerWindow % only in Tracker
                    switch Key
                        case Par.KeyEscape
                            Par.ESC = true;
%                         case Par.KeyTogglePause
%                             if Par.Paused
%                                 Par.Paused = false;
%                             else
%                                 Par.Paused = true;
%                                 Par.BreakTrial=true;
%                             end
                        case Par.KeyTriggerMR
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
                            if ~Par.RequireFixationForReward;
                                Par.RequireFixationForReward = true;
                                Par.WaitForFixation = true;
                                fprintf('Requiring fixation for reward.\n')
                            else
                                Par.RequireFixationForReward = false;
                                Par.WaitForFixation = false;
                                fprintf('Not requiring fixation for reward.\n')
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
            if Par.HandIsIn
                Par.HandIsIn=false;
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Left');
            end
        elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
            Par.BeamLIsBlocked = false;
            if Par.HandIsIn
                Par.HandIsIn=false;
                Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Left');
            end
        else
            Par.BeamLIsBlocked = true;
            if ~Par.HandIsIn
                Par.HandIsIn=true;
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
                if Par.HandIsIn
                    Par.HandIsIn=false;
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Right');
                end
            elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
                Par.BeamRIsBlocked = false;
                if Par.HandIsIn
                    Par.HandIsIn=false;
                    Log.events.add_entry(GetSecs, Stm(1).task.name, 'Response_Release', 'Right');
                end
            else
                Par.BeamRIsBlocked = true;
                if ~Par.HandIsIn
                    Par.HandIsIn=true;
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
            if ~Par.CheckFixIn && ~TestRunstimWithoutDAS
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
            if mod(nf,100)==0 && ~TestRunstimWithoutDAS
                refreshtracker(1);
            end
        end
        % Check if eye leaves fixation window =============================
        if Par.FixIn %fixating
            if ~Par.CheckFixOut && ~TestRunstimWithoutDAS
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
        Log.events.add_entry(StartReward, Stm(1).task.name, 'Reward', 'Manual');
        
    end
% check and update eye info in tracker window
    function fixChange = CheckTracker
        if TestRunstimWithoutDAS
            fixChange = false;
        else
            dasrun(5);
            [fixChange, ~] = DasCheck;
            fixChange = fixChange ~= 0;
        end
    end


end
