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

Stm(1).Task.updateState('PREPARE_STIM');

%% Stimulus preparation ===================================================
for PrepareStim=1
    Stm(1).Task.update();
end % allow code-folding

Stm(1).Task.updateState('INIT_EXPERIMENT');
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
    Par.PosReset=false;
    Par.BreakTrial=false;

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

    if isfield(Par,'MaxTimeBetweenRewardsMin')
        Par.MaxTimeBetweenRewardsSecs = Par.MaxTimeBetweenRewardsMin*60;
    else
        Par.MaxTimeBetweenRewardsSecs = Inf;
    end
end

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
% Structure: preswitch_period-switch_period/switched_duration-postswitch
while ~Par.ESC %===========================================================
    Stm(1).Task.updateState('INIT_TRIAL', lft);
    
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
        Par.CurrFixCol=Stm(1).Task.taskParams.FixDotCol(1,:).*Par.ScrWhite;
        Par.FirstInitDone=true;
        Par.FixInOutTime=[0 0];
        Log.StartBlock=lft;
        lft=Screen('Flip', Par.window);  %initial flip to sync up timing
        nf=0;
        if TestRunstimWithoutDAS; Hit=0; end
        Par.LastRewardTime = GetSecs;
    end
    Par.DrawPawIndNow = false;
    
    % State == INIT_TRIAL
    Stm(1).Task.update();
       
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
    Stm(1).Task.updateState('PREFIXATION', lft);
    Par.FixStart=Inf;
    % what happens during this loop is not logged
    while lft < Par.FixStart+50/1000 && ...
            Par.RequireFixation && ~Par.ESC
        CheckManual;
        Stm(1).Task.checkResponses(lft);
        CheckKeys;
        Stm(1).Task.drawBackgroundFixPoint();
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        if Par.FixIn && Par.FixStart == Inf
            Par.FixStart = lft;
            Stm(1).Task.updateState('FIXATING', Par.FixStart);
        end
        % Get and plot eye position
        CheckTracker;
        % Change stimulus if required
        ChangeStimulus;
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        if GetSecs > Par.LastRewardTime && ...
            Par.LastRewardTime + Par.MaxTimeBetweenRewardsSecs < GetSecs % give reward if its been 2 minutes
            t = GetSecs;
            GiveRewardManual;
            % ConsolatoryRewardTime = lft;
        end
    end
    
    % PRESWITCH -----------------------------------------------------------
    Par.PreSwitchStart=lft;
    Stm(1).Task.updateState('PRESWITCH', Par.PreSwitchStart);
    Par.SwitchOnset=rand(1)*Stm(1).Task.taskParams.EventPeriods(2)/1000;
    while lft < Par.PreSwitchStart + ...
            Stm(1).Task.taskParams.EventPeriods(1)/1000 + Par.SwitchOnset && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        Par.DrawPawIndNow = true;
        %(lft >= ...
        %    Par.PreSwitchStart + Stm(1).Task.taskParams.EventPeriods(1)/1000 - 350/1000);
        
        lft = Stm(1).Task.drawStimuli(lft);
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        Stm(1).Task.checkResponses(lft);
        
        % Get and plot eye position
        CheckTracker;
        
        % Change stimulus if required
        ChangeStimulus;
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManRewThisTrial=[Par.ManRewThisTrial ...
                lft-Par.ExpStart];
            Par.ManualReward=false;
        end
    end
    
    % SWITCHED ------------------------------------------------------------
    Par.SwitchStart=lft;
    Stm(1).Task.updateState('SWITCHED', Par.SwitchStart);
    % switch to orientation 2
    Par.CurrOrient=2;
    % switched
    while lft < Par.SwitchStart+Stm(1).Task.param('SwitchDur')/1000 && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial && ...
            (Par.CurrResponse ~= Par.RESP_CORRECT)
        
        % DrawStimuli
        lft = Stm(1).Task.drawStimuli(lft);
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        CheckKeys; % check for key-presses
        CheckManual; % check for manual (joystick) responses
        
        Stm(1).Task.checkResponses(lft);
        
        % Get and plot eye position
        CheckTracker;
        
        % Change stimulus if required
        ChangeStimulus;
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        %DrawStimuli; % update lifted paw indicator
        lft = Stm(1).Task.drawStimuli(lft);
        
        % Check eye position
        if ~TestRunstimWithoutDAS
            dasrun(5);
            [Hit, Time] = DasCheck;
        end
        
        % give automated reward
        if Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
        
    if Par.CurrResponse > 0 && ...
            isfield(Par, 'FeedbackSound') && ...
            isfield(Par, 'FeedbackSoundPar') && ...
            Par.FeedbackSound(Par.CurrResponse) && ...
            ~isnan(Par.FeedbackSoundPar(Par.CurrResponse,1))
        if Par.FeedbackSoundPar(Par.CurrResponse)
            try
                w = warning ('off','MATLAB:audiovideo:audioplayer:noAudioOutputDevice');
                RewT=0:1/Par.FeedbackSoundPar(Par.CurrResponse,1):Par.FeedbackSoundPar(Par.CurrResponse,4);
                RewY=Par.FeedbackSoundPar(Par.CurrResponse,3)*sin(2*pi*Par.FeedbackSoundPar(Par.CurrResponse,2)*RewT);
                sound(RewY, Par.FeedbackSoundPar(Par.CurrResponse, 1));
                warning(w) % return warning settings to previous state
            catch
                warning(w) % return warning settings to previous state
            end
        end
    end
        
    % switch to orientation 1
    Par.DrawPawIndNow = false;
    Par.CurrOrient=1;
    
    % POSTSWITCH ----------------------------------------------------------
    Par.PostSwitchStart=lft;
    Stm(1).Task.updateState('POSTSWITCH', Par.PostSwitchStart);
    
    while lft < Par.PostSwitchStart + ...
            Stm(1).Task.taskParams.EventPeriods(3)/1000 && ~Par.PosReset && ...
            ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli;
        lft = Stm(1).Task.drawStimuli(lft);
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        Stm(1).Task.checkResponses(lft);
        
        % Get and plot eye position
        CheckTracker;
        
        % Change stimulus if required
        ChangeStimulus;
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        % give automated reward
        if Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
    Par.DrawPawIndNow = false;
    % no response or fix break during switch = miss
    % ~Par.ResponseGiven && ~Par.FalseResponseGiven && ...
    if Par.CurrResponse == Par.RESP_NONE            
        Par.CurrResponse = Par.RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
    end
    
    % Minimum reward
    if GetSecs > Par.LastRewardTime && ...
            Par.LastRewardTime + Par.MaxTimeBetweenRewardsSecs < GetSecs % give reward if its been 2 minutes
        t = GetSecs;
        GiveRewardManual;
        ConsolatoryRewardTime = lft;
    end
    
    % Performance info on screen
    for PerformanceOnCMD=1
        if Par.PosReset
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
            Log.Trial(Par.Trlcount(2)).Finished = false;
        else
            Log.Trial(Par.Trlcount(2)).Finished = true;
        end
        
        % Display total reward every x correct trials
        if Par.CurrResponse == Par.RESP_CORRECT && ...
                mod(Par.Response(Par.RESP_CORRECT),10) == 0 && ...
                Par.Response(Par.RESP_CORRECT) > 0
            
            fprintf(['\nTask: ' Stm(1).Task.taskName '\n']);
        

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

    % LOG TRIAL INFO ------------------------------------------------------
    for LogTrialInfo=1 % allow code folding
        Log.Trial(Par.Trlcount(2)).TrialNr = Par.Trlcount(2);
        Log.Trial(Par.Trlcount(2)).PosNr = Par.PosNr;
        Log.Trial(Par.Trlcount(2)).TrialNrPos = Par.Trlcount(1);
        Log.Trial(Par.Trlcount(2)).PreSwitchStart = ...
            Par.PreSwitchStart-Par.ExpStart;
        Log.Trial(Par.Trlcount(2)).SwitchStart = ...
            Par.SwitchStart-Par.ExpStart;
        Log.Trial(Par.Trlcount(2)).PostSwitchStart = ...
            Par.PostSwitchStart-Par.ExpStart;
        Log.Trial(Par.Trlcount(2)).RespTime = Par.RespTimes;
        Log.Trial(Par.Trlcount(2)).Reward = Par.AutoRewardGiven;
        Log.Trial(Par.Trlcount(2)).RewardAmount = Par.RewardTime;
        Log.Trial(Par.Trlcount(2)).ManualRewards = Par.ManRewThisTrial;
        Log.Trial(Par.Trlcount(2)).ResponseGiven = Par.ResponseGiven;
        Log.Trial(Par.Trlcount(2)).CurrResponse = Par.CurrResponse;
        Log.Trial(Par.Trlcount(2)).CorrectThisTrial = Par.CorrectThisTrial;
    end
    
    % Update Tracker window
    if ~TestRunstimWithoutDAS
        %SCNT = {'TRIALS'};
        SCNT(1) = { ['Corr:  ' num2str(Par.Response(Par.RESP_CORRECT)) ] };
        SCNT(2) = { ['False: ' num2str(Par.Response(Par.RESP_FALSE)) ] };
        SCNT(3) = { ['Miss:  ' num2str(...
            Par.Response(Par.RESP_MISS)+Par.Response(Par.RESP_EARLY)+ ...
            Par.Response(Par.RESP_BREAK_FIX)) ] };
        SCNT(4) = { ['Total: ' num2str(Par.Trlcount(2)) ]};
        if Par.CurrResponse > 0
            SCNT(5) = { [RespText{Par.CurrResponse}]};
        else
            SCNT(5) = {''};
        end
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
    Screen('FillRect',Par.window,Stm(1).Task.param('BGColor').*Par.ScrWhite);
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
    if TestRunstimWithoutDAS; cd ..;end
    mkdir('Log');cd('Log');
    save(FileName,'Log','Par','StimObj');
    cd ..
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
        FixWinSizePix = Stm(1).Task.param('FixWinSizePix');
        Par.WIN = [...
            Stm(1).Task.taskParams.FixPositionsPix(Par.PosNr,:), ...
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
                        case Par.KeyTogglePause
                            if Par.Paused
                                Par.Paused = false;
                            else
                                Par.Paused = true;
                                Par.BreakTrial=true;
                            end
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
                            if ~Par.RequireFixation;
                                Par.RequireFixation = true;
                                fprintf('Requiring fixation.\n')
                            else
                                Par.RequireFixation = false;
                                fprintf('Not requiring fixation.\n')
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
            end
        elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
            Par.BeamLIsBlocked = false;
            if Par.HandIsIn
                Par.HandIsIn=false;
            end
        else
            Par.BeamLIsBlocked = true;
            if ~Par.HandIsIn
                Par.HandIsIn=true;
            end
        end
        
        if Stm(1).Task.taskParams.NumBeams >= 2
            %check the incoming signal on DAS channel #4 (#5 base 1)
            % NB dasgetlevel only starts counting at the third channel (#2)
            % Right / Secondary beam
            Log.RespSignal = ChanLevels(5-2);
            if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 % 64bit das card
                Par.BeamRIsBlocked = false;
                if Par.HandIsIn
                    Par.HandIsIn=false;
                end
            elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
                Par.BeamRIsBlocked = false;
                if Par.HandIsIn
                    Par.HandIsIn=false;
                end
            else
                Par.BeamRIsBlocked = true;
                if ~Par.HandIsIn
                    Par.HandIsIn=true;
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
            
            % Draw fixation dot
            Stm(1).Task.drawFix();
            
            % Check eye position
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, ~] = DasCheck;
            end
            
            if Hit == 1 % eye in fix window (hit will never be 1 is tested without DAS)
                Par.FixIn=true;
                Par.LastFixInTime=GetSecs;
                Par.CurrFixCol=Stm(1).Task.taskParams.FixDotCol(2,:).*Par.ScrWhite;
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
            
            % Draw fixation dot
            Stm(1).Task.drawFix();
            
            % Check eye position
            % DasCheck
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, ~] = DasCheck;
            end
            
            if Hit == 1 % eye out of fix window
                Par.FixIn=false;
                Par.LastFixOutTime=GetSecs;
                Par.CurrFixCol=Stm(1).Task.taskParams.FixDotCol(1,:).*Par.ScrWhite;
                refreshtracker(1);
            end
        end
    end
% give automated reward
    function GiveRewardAuto
        % Get correct reward duration
        switch Par.RewardType
            case 0
                Par.RewardTimeCurrent = Par.RewardTime;
            case 1
                if size(Par.RewardTime,2)>1 % progressive schedule still active
                    % Get number of consecutive correct trials
                    rownr= find(Par.RewardTime(:,1)<Par.CorrStreakcount(2),1,'last');
                    Par.RewardTimeCurrent = Par.RewardTime(rownr,2);
                else %schedule overruled by slider settings
                    Par.RewardTimeCurrent = Par.RewardTime;
                end
            case 2
                Par.RewardTimeCurrent = 0;
        end
        
        if isfield(Stm(1), 'TaskRewardMultiplier')
            Par.RewardTimeCurrent = Par.RewardTimeCurrent * ...
                Stm(1).TaskRewardMultiplier(Stm(1).TaskCycleInd);
        end
        
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
        
    end
% check and update eye info in tracker window
    function CheckTracker
        dasrun(5);
        DasCheck;
    end


end
