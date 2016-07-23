function runstim(Hnd)
% Updated September 2013 Chris Klink
% Manual response photocell on channel 3 of connection box

global Par   %global parameters
global StimObj %stimulus objects
global Log

RESP_NONE = 0;
RESP_CORRECT = 1;
RESP_FALSE = 2;
RESP_MISS = 3;
RESP_EARLY = 4;
RESP_BREAK_FIX = 5;

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

%% Stimulus preparation ===================================================
for PrepareStim=1
    % Fixation
    Stm(1).FixWinSizePix = round(Stm(1).FixWinSize*Par.PixPerDeg);
    Stm(1).FixDotSizePix = round(Stm(1).FixDotSize*Par.PixPerDeg);
    
    % Bar
    Stm(1).SizePix = round(Stm(1).Size.*Par.PixPerDeg);
    Stm(1).Center =[];
    for i=1:size(Stm(1).Position,2);
        Stm(1).Center =[Stm(1).Center; ...
            round(Stm(1).Position{i}.*Par.PixPerDeg)];
    end
    Par.CurrOrient=1; % 1=default, 2=switched
    
    % Paw indicator
    Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
    Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);
    
    RandomizePawIndOffset();
    Par.PawSide=randi([1,2]);
    
    Par.Paused = false;
    Par.unattended_alpha = max(Stm(1).UnattdAlpha);
        
    % Noise patch
    Stm(1).NoiseSizePix = round(Stm(1).NoiseSize.*Par.PixPerDeg);
    % Square noise patch of window-height
    NoiPatch = (.5-Stm(1).NoiseContrast/2) + ...
        (Stm(1).NoiseContrast.*rand(Par.HH*2));
    NoiPatch_RGB = ones(Par.HH*2,Par.HH*2,4);
    NoiPatch_RGB(:,:,1)=NoiPatch;
    NoiPatch_RGB(:,:,2)=NoiPatch;
    NoiPatch_RGB(:,:,3)=NoiPatch;
    % alpha mask circular
    c=Par.HH;
    s=Par.HH*2;
    r=Stm(1).NoiseSizePix/2;
    [x,y]=meshgrid(-(c-1):(s-c),-(c-1):(s-c));
    alphamask=((x.^2+y.^2)<=r^2);
    NoiPatch_RGB(:,:,4)=alphamask;
    % Make a texture of the noise patch
    NoiTex=Screen('MakeTexture',Par.window,NoiPatch_RGB.*Par.ScrWhite);
end % allow code-folding

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
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
    lft=Screen('Flip', Par.window);
    lft=Screen('Flip', Par.window, lft+1);
    Par.ExpStart = lft;
    
    % Initial stimulus position is 1
    Par.PosNr=1;
    Par.PrevPosNr=1;
    
    % Initial draw-background-status
    Par.DrawNoise = Stm(1).NoiseDefaultOn;
    
    % Initialize KeyLogging
    Par.KeyIsDown=false;
    Par.KeyWasDown=false;
    
    % Initialize photosensor manual response
    Par.BeamLIsBlocked=false;  Par.BeamRIsBlocked=false;
    Par.BeamLWasBlocked=false; Par.BeamRWasBlocked=false;
    Par.NewResponse = false;
    Par.GoNewTrial = false;
    
    % Initialize control parameters
    Par.SwitchPos = false;
    Par.ToggleNoisePatch = false;
    Par.ToggleDistract = false;
    Par.ToggleCyclePos = true; % overrules the Stim(1)setting; toggles with 'p'
    Par.ManualReward = false;
    Par.PosReset=false;
    Par.BreakTrial=false;
    
    % Trial Logging
    Par.CurrResponse = RESP_NONE;
    Par.Response = [0 0 0 0 0]; %[correct false-hit missed]
    Par.ResponsePos = [0 0 0 0 0]; %[correct false-hit missed]
    Par.RespTimes = [];
    Par.ManRewThisTrial=[];
    
    Par.FirstInitDone=false;
    Par.CheckFixIn=false;
    Par.CheckFixOut=false;
    Par.CheckTarget=false;
    Par.RewardRunning=false;
    
    Par.State='Init';
end

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
% Structure: preswitch_period-switch_period/switched_duration-postswitch
while ~Par.ESC %===========================================================
    Par.State='INIT';
    while ~Par.FirstInitDone
        %set control window positions and dimensions
        if ~TestRunstimWithoutDAS
            DefineEyeWin;
            refreshtracker(1); %for your control display
            SetWindowDas;      %for the dascard, initializes eye control windows
        end
        
        Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
        
        Par.CurrResponse = RESP_NONE;
        Par.ResponseGiven=false;
        Par.FalseResponseGiven=false;
        Par.RespValid = false;
        Par.CorrectThisTrial = false;
        Par.TaskSwitched = true;
        Par.LastFixInTime=0;
        Par.LastFixOutTime=0;
        Par.FixIn=false; %initially set to 'not fixating'
        Par.CurrFixCol=Stm(1).FixDotCol(1,:).*Par.ScrWhite;
        Par.FirstInitDone=true;
        Par.FixInOutTime=[0 0];
        Log.StartBlock=lft;
        lft=Screen('Flip', Par.window);  %initial flip to sync up timing
        nf=0;
        if TestRunstimWithoutDAS; Hit=0; end
        Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
    end
    Par.DrawPawIndNow = false;
    
    % If required, pause here until beam is no longer interrupted
    if Stm(1).OnlyStartTrialWhenBeamIsNotBlocked
        while (~Par.GoNewTrial || Par.Paused) && ~Par.ESC
            CheckManual;
            CheckKeys;
            DrawNoiseOnly;
            
            % Check eye fixation ----------------------------------------------
            CheckFixation;
            % Get and plot eye position
            CheckTracker;
            % Change stimulus if required
            ChangeStimulus;
            
            % give manual reward
            if Par.ManualReward
                GiveRewardManual;
                Par.ManualReward=false;
            end
        end
    end
    
    % Allow for task to be changed
    Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
    Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);
    
    % Chance of changing sides
    if Par.PawSide==1 % currently left side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(2))
            Par.PawSide=2; % switch to right
            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
        end
    else % currently right side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(2))
            Par.PawSide=1; % switch to left
            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
        end
    end
    if Par.CorrectThisTrial || Par.TaskSwitched
        if Stm(1).Task == Stm(1).TASK_TARGET_AT_CURVE
            min_alpha = min(Stm(1).UnattdAlpha);
            max_alpha = max(Stm(1).UnattdAlpha);
        elseif  Stm(1).Task == Stm(1).TASK_TARGET_AT_FIX
            min_alpha = min(Stm(1).UnattdAlpha_TargetAtFix);
            max_alpha = max(Stm(1).UnattdAlpha_TargetAtFix);
        else
            min_alpha = 0;
            max_alpha = 0;
        end
        % Alpha (opacity) of distractor
        Par.unattended_alpha = (max_alpha-min_alpha)*rand() + min_alpha;
        Par.unattended_alpha = min(1.0, Par.unattended_alpha);
        Par.unattended_alpha = max(0.0, Par.unattended_alpha);
    end
    Par.TaskSwitched = false;
    Par.PawOppSide=mod(Par.PawSide,2)+1;
    
    RandomizePawIndOffset();
    
    if Par.CorrectThisTrial
        Par.SwitchableInNumTrials = Par.SwitchableInNumTrials - 1;
    end
    
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.CurrResponse = RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    
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
    Par.State='PREFIXATION';
    Par.FixStart=Inf;
    while lft < Par.FixStart+50/1000 && ...
            Stm(1).RequireFixation && ~Par.ESC
        CheckManual;
        CheckKeys;
        DrawNoiseOnly;

        % Check eye fixation ----------------------------------------------
        CheckFixation;
        if Par.FixIn && Par.FixStart == Inf
            Par.FixStart = lft;
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
    end
    
    % PRESWITCH -----------------------------------------------------------
    Par.State='PRESWITCH';
    Par.PreSwitchStart=lft;
    Par.SwitchOnset=rand(1)*Stm(1).EventPeriods(2)/1000;
    while lft < Par.PreSwitchStart + ...
            Stm(1).EventPeriods(1)/1000 + Par.SwitchOnset && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        Par.DrawPawIndNow = true;
        %(lft >= ...
        %    Par.PreSwitchStart + Stm(1).EventPeriods(1)/1000 - 350/1000);
        
        % DrawStimuli
        DrawStimuli;
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse
            % false hit / early response
            Par.RespValid = false;
            Par.CurrResponse = RESP_EARLY;
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
        elseif ~Par.FixIn && Stm(1).RequireFixation
            % false
            Par.RespValid = false;
            Par.CurrResponse = RESP_BREAK_FIX;
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
            Par.FalseResponseGiven=false;
            Par.BreakTrial=true;
        end
        
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
    Par.State='SWITCHED';
    Par.SwitchStart=lft;
    % switch to orientation 2
    Par.CurrOrient=2;
    % switched
    while lft < Par.SwitchStart+Stm(1).SwitchDur/1000 && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli
        DrawStimuli;
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse && ...
                lft >= Par.SwitchStart+Stm(1).ResponseAllowed(1)/1000 && ...
                lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
            % correct
            if ~Stm(1).RequireSpecificPaw || Par.NewResponse == Par.PawSide
                Par.RespValid = true;
                Par.CurrResponse = RESP_CORRECT;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    Par.CorrectThisTrial=true;
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~Stm(1).RequireSpecificPaw || Par.NewResponse ~= Par.PawSide
                % false
                Par.RespValid = false;
                Par.CurrResponse = RESP_FALSE;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                end
                Par.FalseResponseGiven=true;
                if Stm(1).BreakOnFalseHit
                    Par.BreakTrial=true;
                end
            %else
            %    Par.NewResponse = false;
            end
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
        elseif Par.NewResponse % early or late
            % false
            Par.RespValid = false;
            if lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
                Par.CurrResponse = RESP_EARLY;
            else
                Par.CurrResponse = RESP_MISS;
            end
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
        elseif ~Par.FixIn && Stm(1).RequireFixation
            % false
            Par.CurrResponse = RESP_BREAK_FIX;
            Par.RespValid = false;
            if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                %Par.ResponsePos
                Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
            end
            Par.FalseResponseGiven=false;
            Par.BreakTrial=true;
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
        
        
        % Draw fixation dot
        DrawFix;
        
        % Check eye position
        if ~TestRunstimWithoutDAS
            dasrun(5);
            [Hit, Time] = DasCheck;
        end
        
        % give automated reward
        if Stm(1).AutoReward && Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
        
    end
    % switch to orientation 1
    Par.DrawPawIndNow = false;
    Par.CurrOrient=1;
    
    % POSTSWITCH ----------------------------------------------------------
    Par.State='POSTSWITCH';
    Par.PostSwitchStart=lft;
    
    while lft < Par.PostSwitchStart + ...
            Stm(1).EventPeriods(3)/1000 && ~Par.PosReset && ...
            ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli
        DrawStimuli;
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse && ...
                lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
            
            % correct
            if ~Stm(1).RequireSpecificPaw || Par.NewResponse == Par.PawSide
                Par.RespValid = true;
                Par.CurrResponse = RESP_CORRECT;
                if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    Par.CorrectThisTrial=true;
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~Stm(1).RequireSpecificPaw || Par.NewResponse ~= Par.PawSide
                % false
                Par.RespValid = false;
                Par.CurrResponse = RESP_FALSE;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                end
                Par.FalseResponseGiven=true;
                if Stm(1).BreakOnFalseHit
                    Par.BreakTrial=true;
                end
%            else
%                Par.NewResponse = false;
            end
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
%             % correct
%             Par.RespValid = true;
%             DrawStimuli;
%             if ~Par.ResponseGiven %only log once
%                 Par.Response(1)=Par.Response(1)+1;
%                 Par.ResponsePos(1)=Par.ResponsePos(1)+1;
%                 Par.CorrectThisTrial=true;
%             end
%             Par.ResponseGiven=true;
%             Par.RespTimes=[Par.RespTimes;
%                 lft-Par.ExpStart Par.RespValid];
%             Par.CorrStreakcount=Par.CorrStreakcount+1;
        elseif Par.NewResponse
            % Miss
            Par.CurrResponse = RESP_MISS;
            Par.RespValid = false;
            Par.FalseResponseGiven=true;
            if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
            end
            %Par.ResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            %Don't break trial, this would speed it up and be positive
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
        
        % give automated reward
        if Stm(1).AutoReward && Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
    Par.DrawPawIndNow = false;
    % no response during switch = miss
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven
        Par.CurrResponse = RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
    end
    
    % Consolatory reward
    if ~Par.AutoRewardGiven && ~Par.FalseResponseGiven && ...
            (Stm(1).RequireFixation && rand() < Stm(1).ProbFixationReward && ...
                Par.FixIn || ...
             ~Stm(1).RequireFixation && rand() < Stm(1).ProbConsolatoryReward ...
            ) && ~Par.Paused
        GiveRewardManual;
        Par.ManualReward=false;
        ConsolatoryRewardTime = lft;
    end
    
    % Break for false hit
    Par.BreakStartTime=lft;
    while lft < Par.BreakStartTime + Stm(1).BreakDuration/1000 && ~Par.ESC && Par.BreakTrial
        CheckManual;
        CheckKeys; % internal function
        DrawNoiseOnly;
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
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
    
    % Switch position if required to do this automatically
    if Par.ToggleCyclePos && Stm(1).CyclePosition && ...
            Log.Trial(Par.Trlcount(2)).TrialNrPos >= Stm(1).CyclePosition
        % next position
        Par.SwitchPos = true;
        Par.WhichPos = 'Next';
        ChangeStimulus;
        Par.SwitchPos = false;
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
        
        % Display total reward every 50 trials
        if mod(Par.Trlcount(2),50) == 0
            fprintf(['\nT: ' ...
                num2str(Par.Trlcount(2)) ...
                ', C: ' ...
                num2str(Par.Response(1)) ...
                ', M: ' ...
                num2str(Par.Response(3)) ...
                ', F: ' ...
                num2str(Par.Response(2)) ...
                ', TotRew: ' ...
                num2str(Log.TotalReward) '\n\n']);
            Log.TCMFR = [Log.TCMFR; ...
                Par.Trlcount(2) ...
                Par.Response(1) ...
                Par.Response(3) ...
                Par.Response(2) ...
                Log.TotalReward];
            fprintf(['\nPercent correct paw: ',...
                num2str( round(100 * ...
                Par.Response(RESP_CORRECT)/...
                (Par.Response(RESP_CORRECT) + ...
                    Par.Response(RESP_FALSE))))...
                '\n\n'])
            fprintf(['\nFixation percentage: ',...
                num2str( round(100*...
                (Par.Response(RESP_CORRECT) + ...
                    Par.Response(RESP_FALSE) + ...
                    Par.Response(RESP_MISS))/...
                (Par.Response(RESP_CORRECT) + ...
                    Par.Response(RESP_FALSE) + ...
                    Par.Response(RESP_BREAK_FIX) + ...
                    Par.Response(RESP_MISS) + ...
                    Par.Response(RESP_EARLY)))) ...
                '\n\n'])
                
        end
    end
    
    % Update Tracker window
    if ~TestRunstimWithoutDAS
        %SCNT = {'TRIALS'};
        SCNT(1) = { ['Corr:  ' num2str(Par.Response(RESP_CORRECT)) ] };
        SCNT(2) = { ['False: ' num2str(Par.Response(RESP_FALSE)) ] };
        SCNT(3) = { ['Miss:  ' num2str(...
            Par.Response(RESP_MISS)+Par.Response(RESP_EARLY)+ ...
            Par.Response(RESP_BREAK_FIX)) ] };
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
        
        
        %fprintf(['Percent correct = ' ...
        %    num2str(100*Par.Trlcount(RESP_CORRECT) / ...
        %    (Par.Trlcount(RESP_CORRECT)+Par.Response(RESP_FALSE)))])
    end
end

%% Clean up and Save Log ==================================================
for CleanUp=1 % code folding
    % Empty the screen
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
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
        Par.WIN = [...
            Stm(1).Center(Par.PosNr,1), ...
            -Stm(1).Center(Par.PosNr,2), ...
            Stm(1).FixWinSizePix, ...
            Stm(1).FixWinSizePix, FIX]';
        refreshtracker( 1) %clear tracker screen and set fixation and target windows
        SetWindowDas; %set das control thresholds using global parameters : Par
    end
% draw stimuli
    function DrawStimuli
        % Background
        Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        
        % Noise patch
        if Par.DrawNoise
            srcRect = [Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5 ...
                Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
            destRect = [Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-(Stm(1).NoiseSizePix/2)-5 ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+(Stm(1).NoiseSizePix/2)+5 ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
            Screen('DrawTexture',Par.window,NoiTex,srcRect,destRect);
        end
        
        if Stm(1).RequireSpecificPaw && Par.DrawPawIndNow
            
            PawIndSizePix = Stm(1).PawIndSizePix;
            
            % Fixation position
            hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
            vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
            fix_pos = ...
                [hfix, vfix; ...
                 hfix, vfix; ...
                 hfix, vfix; ...
                 hfix, vfix];
            if Par.PawSide == 1 % subtract offset, to put to the left
                attd_offset = ...
                    [ -Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      -Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      -Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      -Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2)];
            else
                attd_offset = ...
                    [ Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2); ...
                      Stm(1).PawIndOffsetPix(1), Stm(1).PawIndOffsetPix(2)];
            end
            for define_square=1 % left / square
                lmost=-PawIndSizePix/2;
                rmost= PawIndSizePix/2;
                tmost=-PawIndSizePix/2;
                bmost= PawIndSizePix/2;
                left_square = [lmost,tmost; ...
                      rmost,tmost; ...
                      rmost,bmost; ...
                      lmost,bmost ...
                      ];
            end
            for define_diamond=1 % right / diamond
                lmost=-sqrt(2)*PawIndSizePix/2;
                rmost= sqrt(2)*PawIndSizePix/2;
                tmost=-sqrt(2)*PawIndSizePix/2;
                bmost= sqrt(2)*PawIndSizePix/2;
                right_diamond = [lmost,0; ...
                      0,tmost; ...
                      rmost,0; ...
                      0,bmost ...
                      ];
            end
            if mod(Stm(1).Task, 2) == Stm(1).TASK_TARGET_AT_FIX
                % Everything not at target is distractor
                color = (...
                    Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                    Stm(1).TraceCurveCol * Par.unattended_alpha) * Par.ScrWhite;
                Screen('DrawLine', Par.window, ...
                    color, ...
                    hfix, vfix, ...
                    hfix + Par.DistractLineTarget * attd_offset(1,1), ...
                    vfix + Par.DistractLineTarget * attd_offset(1,2),...
                    Stm(1).TraceCurveWidth);
                color = (...
                    Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                    Stm(1).PawIndCol(Par.PawSide,:) * Par.unattended_alpha) * Par.ScrWhite;
%                 color = [...
%                     Stm(1).PawIndCol(Par.PawSide,:), ...
%                     Par.unattended_alpha].*Par.ScrWhite;
            else
                Screen('DrawLine', Par.window, ...
                    Stm(1).TraceCurveCol, hfix, vfix, ...
                    hfix + attd_offset(1,1), vfix + attd_offset(1,2),...
                    Stm(1).TraceCurveWidth);
                color = [...
                    Stm(1).PawIndCol(Par.PawSide,:), ...
                    1.0].*Par.ScrWhite;
            end
            if Par.PawSide == 1
                Screen('FillPoly',Par.window,...
                    color,...
                    fix_pos + left_square + attd_offset);
            else
                Screen('FillPoly',Par.window,...
                    color,...
                    fix_pos + right_diamond + attd_offset);
            end
            unattd_offset = -attd_offset;
            Unattd_color = [...
                Stm(1).PawIndCol(Par.PawOppSide,:), ...
                Par.unattended_alpha].*Par.ScrWhite;
            
            Unattd_color = (...
                Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                Stm(1).PawIndCol(Par.PawOppSide,:) * Par.unattended_alpha) * Par.ScrWhite;
            if Par.PawSide == 1
                Screen('FillPoly',Par.window,...
                    Unattd_color,...
                    fix_pos + right_diamond + unattd_offset);
            else
                Screen('FillPoly',Par.window,...
                    Unattd_color,...
                    fix_pos + left_square + unattd_offset);
            end
        end
        
        DrawFix;
        
        if mod(Stm(1).Task, 2) == Stm(1).TASK_TARGET_AT_FIX && ...
                Stm(1).RequireSpecificPaw && Par.DrawPawIndNow
            
            PawIndSizePix = Stm(1).FixTargetSizePix;
            
            % Fixation position
            hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
            vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
            fix_pos = ...
                [hfix, vfix; ...
                 hfix, vfix; ...
                 hfix, vfix; ...
                 hfix, vfix];
            attd_offset = [0 0; 0 0; 0 0; 0 0]; 
            
            for define_square=1 % left / square
                lmost=-PawIndSizePix/2;
                rmost= PawIndSizePix/2;
                tmost=-PawIndSizePix/2;
                bmost= PawIndSizePix/2;
                left_square = [lmost,tmost; ...
                      rmost,tmost; ...
                      rmost,bmost; ...
                      lmost,bmost ...
                      ];
            end
            for define_diamond=1 % right / diamond
                lmost=-sqrt(2)*PawIndSizePix/2;
                rmost= sqrt(2)*PawIndSizePix/2;
                tmost=-sqrt(2)*PawIndSizePix/2;
                bmost= sqrt(2)*PawIndSizePix/2;
                right_diamond = [lmost,0; ...
                      0,tmost; ...
                      rmost,0; ...
                      0,bmost ...
                      ];
            end
            Screen('DrawLine', Par.window, ...
                Stm(1).TraceCurveCol, hfix, vfix, ...
                hfix + attd_offset(1,1), vfix + attd_offset(1,2),...
                Stm(1).TraceCurveWidth);
            
            % Draw Side Indicator
            if Par.PawSide == 1
                Screen('FillPoly',Par.window,...
                    Stm(1).PawIndCol(Par.PawSide,:).*Par.ScrWhite,...
                    fix_pos + left_square + attd_offset);
            else
                Screen('FillPoly',Par.window,...
                    Stm(1).PawIndCol(Par.PawSide,:).*Par.ScrWhite,...
                    fix_pos + right_diamond + attd_offset);
            end
        end
        
        % Target bar - "Go bar"
        if ~Stm(1).Orientation(Par.CurrOrient) %horizontal
            rect=[...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(1)/2, ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(2)/2, ...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(1)/2, ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).SizePix(2)/2];
        else
            rect=[...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(2)/2, ... left
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(1)/2, ... top
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(2)/2, ... right
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).SizePix(1)/2];
        end
        if ~Stm(1).Orientation(Par.CurrOrient) || Stm(1).ShowDistractBar
            Screen('FillRect',Par.window,Stm(1).Color.*Par.ScrWhite,rect);
        end
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    end
% draw stimuli
    function DrawNoiseOnly
        % Background
        Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        if Par.Paused
            % Dark background
            Screen('FillRect',Par.window, 0.0 * Par.BG.*Par.ScrWhite);
        elseif ~Par.GoNewTrial
            if strcmp(Par.State,'INIT')
%                 if Stm(1).NumBeams == 2 && Par.BeamLIsBlocked
%                     Screen('DrawLine', Par.window, ...
%                         Stm(1).PawIndCol(1,:), ...
%                         0, 0, ...
%                         0, Par.ScreenHeightD2);
%                 end
%                 if Stm(1).NumBeams == 2 && Par.BeamRIsBlocked
%                     Screen('DrawLine', Par.window, ...
%                         Stm(1).PawIndCol(2,:), ...
%                         Par.ScreenWidthD2, 0, ...
%                         Par.ScreenWidthD2, Par.ScreenHeightD2);
%                 end
                
                % Semi-dark / brown background
                Screen('FillRect',Par.window, [.5 .25 0].*Par.ScrWhite);
            else
                % Dark background
                Screen('FillRect',Par.window, 0.0 * Par.BG.*Par.ScrWhite);
            end
        end
        if ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked && ~Par.Paused
            % Noise patch
            if Par.DrawNoise
                srcRect = [Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                    Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                    Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5 ...
                    Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
                destRect = [Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-(Stm(1).NoiseSizePix/2)-5 ...
                    Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                    Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+(Stm(1).NoiseSizePix/2)+5 ...
                    Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
                Screen('DrawTexture',Par.window,NoiTex,srcRect,destRect);
            end
            % Draw fixation dot
            DrawFix;
        end
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        
    end
% draw fixation
    function DrawFix
        rect=[...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).FixDotSizePix/2];
        if Stm(1).RequireFixation
            % fixation area
            Screen('FillOval',Par.window, Par.CurrFixCol, rect);
        else
            Screen('FillOval',Par.window, Stm(1).FixDotCol(3,:).*Par.ScrWhite, rect);
        end
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
        % Toggle show distracter
        if Par.ToggleDistract
            if ~Stm(1).ShowDistractBar
                Stm(1).ShowDistractBar = true;
            else
                Stm(1).ShowDistractBar = false;
            end
            Par.ToggleDistract = false;
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
                        Log.MRI.TriggerReceived = true;
                        Log.MRI.TriggerTime = ...
                            [Log.MRI.TriggerTime; Par.KeyTime];
                    case Par.KeyJuice
                        Par.ManualReward = true;
                        Log.ManualRewardTime = ...
                            [Log.ManualRewardTime; Par.KeyTime];
                    case Par.KeyBackNoise
                        Par.ToggleNoisePatch = true;
                    case Par.KeyDistract
                        Par.ToggleDistract = true;
                    case Par.KeyCyclePos
                        if Par.ToggleCyclePos
                            Par.ToggleCyclePos = false;
                            fprintf('Toggle position cycling: OFF\n');
                        else
                            Par.ToggleCyclePos = true;
                            fprintf('Toggle position cycling: ON\n');
                        end
                    case Par.KeyCyclePawSide
                        if Par.PawSide==1
                            Par.PawSide=2;
                        else
                            Par.PawSide=1;
                        end
                    case Par.KeyCycleTask
                        Stm(1).Task = mod(Stm(1).Task + 1, ...
                            Stm(1).TASK_TARGET_AT_FIX_NO_DISTRACTOR + 1);
                        Par.TaskSwitched = true;
                        Stm(1).Task
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
                        Stm(1).RequireFixation = ~Stm(1).RequireFixation;
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
        
        if Stm(1).NumBeams >= 2
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
            % Draw stimulus
%             if LoadStimuli
%                 DrawStimuli;
%                 if ~Stm(1).IsPreDur && ~Par.ToggleHideStim
%                     Screen('DrawTexture',Par.window,VidTex,[],...
%                         [Par.HW-Par.HH 0 Par.HW+Par.HH Par.HH*2 ],[],1);
%                     Par.VidTexDrawn=true;
%                 end
%             end
            
            % Draw fixation dot
            DrawFix;
            
            % Check eye position
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, Time] = DasCheck;
            end
            
            if Hit == 1 % eye in fix window (hit will never be 1 is tested without DAS)
                Par.FixIn=true;
                Par.LastFixInTime=GetSecs;
                Par.CurrFixCol=Stm(1).FixDotCol(2,:).*Par.ScrWhite;
                Par.Trlcount=Par.Trlcount+1;
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
            DrawFix;
            
            % Check eye position
            % DasCheck
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, Time] = DasCheck;
            end
            
            if Hit == 1 % eye out of fix window
                Par.FixIn=false;
                Par.LastFixOutTime=GetSecs;
                Par.CurrFixCol=Stm(1).FixDotCol(1,:).*Par.ScrWhite;
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
        
    end
% check and update eye info in tracker window
    function CheckTracker
        dasrun(5);
        DasCheck;
    end

    function RandomizePawIndOffset
        Stm(1).PawIndOffsetPix(1) = ...
            round((Stm(1).PawIndOffsetX(1) + ...
                rand()*(Stm(1).PawIndOffsetX(2)-Stm(1).PawIndOffsetX(1))) * Par.PixPerDeg);
        Stm(1).PawIndOffsetPix(2) = ...
            datasample([-1 1],1) * ...
            round((Stm(1).PawIndOffsetY(1) + ...
                rand()*(Stm(1).PawIndOffsetY(2)-Stm(1).PawIndOffsetY(1))) * Par.PixPerDeg);
            
        if rand() < 0.5
            Par.DistractLineTarget = -1;
        else
            Par.DistractLineTarget = 1;
        end
    end
end
