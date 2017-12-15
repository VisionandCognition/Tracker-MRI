function runstim(Hnd)
% Updated April 2017 Chris Klink
global Par StimObj Log %global parameters

%% Initialize button responses --------------------------------------------
RESP_NONE = 0;
RESP_CORRECT = 1;
RESP_FALSE = 2;
RESP_MISS = 3;
RESP_EARLY = 4;
RESP_BREAK_FIX = 5;

RespText = {'Correct', 'False', 'Miss', 'Early', 'Fix. break'};

%% THIS SWITCH ALLOW TESTING THE RUNSTIM WITHOUT DASCARD & TRACKER ========
TestRunstimWithoutDAS = false;

%%  Do This Only For Testing Without DAS ----------------------------------
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
clc;

%% Update stim/par-settings without restarting Tracker --------------------
%ParSettings; % this is the old way of hardcoding a ParSettings file
eval(Par.PARSETFILE); % takes ParSettings file chosen via the context menu
Stm = StimObj.Stm;

%% Stimulus preparation ===================================================
% Fixation ----------------------------------------------------------------
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

% Paw indicator -----------------------------------------------------------
Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);

%Par.PawSide=randi([1,2]);
% PawSides indicate the side (1 or 2) for each paw indicator
% Side 1 is left (green square)
% Side 2 is right (red diamond)
% The first PawSides is the indicator that should be attended
if Stm(1).NumOfPawIndicators > 1
    Par.PawSides(:) = 0;
    for i = 1:Stm(1).NumOfPawIndicators/2
        Par.PawSides(2*i-1:2*i) = randperm(2);
    end
else
    Par.PawSides = randi([1,2]);
end
RandomizePawIndOffset();

if ~isfield(Par, 'AutoCycleTasks')
    Par.AutoCycleTasks = 0; % do not cycle tasks automatically
end
if ~isfield(Stm(1), 'DisplayChosenTargetDur')
    Stm(1).DisplayChosenTargetDur = 0;
end

Par.Paused = false;
Par.unattended_alpha = max(Stm(1).UnattdAlpha); % redefined later, randomly
Par.trial_preswitch_alpha = max(Stm(1).AlphaPreSwitch);

% Noise patch -------------------------------------------------------------
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

%% Code Control Preparation ===============================================
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
Par.ToggleDistract = false;
Par.ToggleCyclePos = true; % overrules the Stim(1)setting; toggles with 'p'
Par.ManualReward = false;
Par.PosReset=false;
Par.BreakTrial=false;

% Trial Logging
Par.CurrResponse = RESP_NONE;
Par.Response = [0 0 0 0 0]; %[correct false-hit missed]
Par.ResponsePos = [0 0 0 0 0]; %[correct false-hit missed]
Par.ResponseSide = [0 0 0 0 0; 0 0 0 0 0]; %[left-hand stats; right-hand stats ]
Par.RespTimes = [];

Par.FirstInitDone=false;
Par.CheckFixIn=false;
Par.CheckFixOut=false;
Par.CheckTarget=false;
Par.RewardRunning=false;

Par.State='Init';
if isfield(Par,'MaxTimeBetweenRewardsMin')
    Par.MaxTimeBetweenRewardsSecs = Par.MaxTimeBetweenRewardsMin*60;
else
    Par.MaxTimeBetweenRewardsSecs = Inf;
end
if ~isfield(Stm(1),'PawIndAlpha')
    Stm(1).PawIndAlpha = [1 1 1 1; 1 1 1 1];
end
if ~isfield(Stm(1), 'FalseHitRewardRatio')
    Stm(1).FalseHitRewardRatio = 0;
end
assert(Stm(1).FalseHitRewardRatio <= 1.0, ...
    'It doesn''t make sense to reward more when subject does the wrong thing!')

if size(Stm(1).PawIndAlpha,1)==1
    Stm(1).PawIndAlpha = [ ...
        Stm(1).PawIndAlpha; ... PreSwitch Alpha
        Stm(1).PawIndAlpha ... PostSwitchAlpha
        ];
end

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
% Structure: preswitch_period-switch_period/switched_duration-postswitch

while ~Par.ESC %===========================================================
    %% INIT ---------------------------------------------------------------
    Par.State='INIT';
    while ~Par.FirstInitDone
        %set control window positions and dimensions
        if ~TestRunstimWithoutDAS
            DefineEyeWin;
            refreshtracker(1); %for your control display
            SetWindowDas;      %for the dascard, initializes eye control windows
        end
        
        %Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
        % >> this causes a skipping of trial #1 as it is updated again
        % later on
        
        Par.CurrResponse = RESP_NONE;
        Par.ResponseGiven=false;
        Par.LastResponse = RESP_NONE;
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
        Par.LastRewardTime = GetSecs;
        Par.ManRewThisTrial=nan;
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
    if Stm(1).OnlyStartTrialWhenBeamIsNotBlocked && ...
            (Par.LastResponse == RESP_CORRECT) && ...  || Par.LastResponse == RESP_FALSE
            isfield(Par, 'GiveRewardForUnblockingBeam') && ...
            Par.GiveRewardForUnblockingBeam
        GiveRewardAuto;
        %Par.ManualReward=false;
    end
    Par.ResponsePreviouslyGiven = false;
    
    % Allow for task to be changed
    Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
    Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);
    
    % Chance of changing sides
    if Par.PawSides(1)==1 % currently left side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(2))
            
            Par.PawSides(1) = 2; % switch to right
            
            if Stm(1).NumOfPawIndicators > 1
                Par.PawSides(2:end) = 0;
                % Paw indicator 2 should be opposite of 1
                Par.PawSides(2) = mod(Par.PawSides(1),2)+1;
                % others can choose randomly
                for i = 2:Stm(1).NumOfPawIndicators/2
                    Par.PawSides(2*i-1:2*i) = randperm(2);
                end
            end
            
            % reset counter
            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
        end
    else % currently right side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(2))
            
            Par.PawSides(1) = 1; % switch to left
            
            if Stm(1).NumOfPawIndicators > 1
                Par.PawSides(2:end) = 0;
                % Paw indicator 2 should be opposite of 1
                Par.PawSides(2) = mod(Par.PawSides(1),2)+1;
                % others can choose randomly
                for i = 2:Stm(1).NumOfPawIndicators/2
                    Par.PawSides(2*i-1:2*i) = randperm(2);
                end
            end
            
            % reset counter
            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
        end
    end
    
    Par.PartConnectedTarget = randperm(2, 1)+2;
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
        
        
        min_alpha = min(Stm(1).AlphaPreSwitch);
        max_alpha = max(Stm(1).AlphaPreSwitch);
        Par.trial_preswitch_alpha = (max_alpha-min_alpha)*rand() + min_alpha;
        Par.trial_preswitch_alpha = min(1.0, Par.trial_preswitch_alpha);
        Par.trial_preswitch_alpha = max(0.0, Par.trial_preswitch_alpha);
    end
    Par.TaskSwitched = false;
    Par.PawWrongSide=mod(Par.PawSides(1),2)+1;
    
    RandomizePawIndOffset();
    min_alpha = min(Stm(1).PostSwitchJointAlpha);
    max_alpha = max(Stm(1).PostSwitchJointAlpha);
    post_switch_joint_alpha = rand()*(...
        max_alpha - min_alpha) + min_alpha;
    post_switch_joint_alpha = min(1, max(0, post_switch_joint_alpha));
    
    % countdown number of correct trials without switching
    if Par.CorrectThisTrial
        Par.SwitchableInNumTrials = Par.SwitchableInNumTrials - 1;
    end
    
    % initiate at every new trial
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.CurrResponse = RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    Par.TrialResponse = false;
    Par.ManRewThisTrial=nan;
    Par.ManResp4Log = nan;

    % Eye Window preparation
    for PrepareEyeWin=1
        DefineEyeWin;
    end
    if ~TestRunstimWithoutDAS
        dasreset( 0 );
    end
    
    % Check eye fixation
    CheckFixation;
    
    % Wait for fixation --------------------------------------------------
    Par.State='PREFIXATION';
    Par.FixStart=Inf;
    % what happens during this loop is not logged
    while lft < Par.FixStart+50/1000 && ...
            Par.RequireFixation && ~Par.ESC
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
        
        if GetSecs > Par.LastRewardTime && ...
                Par.LastRewardTime + Par.MaxTimeBetweenRewardsSecs < GetSecs % give reward if its been 2 minutes
            t = GetSecs;
            GiveRewardManual;
            % ConsolatoryRewardTime = lft;
        end
    end
    
    %% PRESWITCH ----------------------------------------------------------
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
            
            % NewResponse indicates left or right responses
            Par.ManResp4Log = Par.NewResponse;
            Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
                Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
        elseif ~Par.FixIn && Par.RequireFixation
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
    
    %% SWITCHED -----------------------------------------------------------
    Par.State='SWITCHED';
    Par.SwitchStart=lft;
    % switch to orientation 2
    Par.CurrOrient=2;
    % switched
    while lft < Par.SwitchStart+Stm(1).SwitchDur/1000 && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial && ...
            (Par.CurrResponse ~= RESP_CORRECT)
        
        % DrawStimuli
        DrawStimuli;
        
        % Check eye fixation
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse && ...
                lft >= Par.SwitchStart+Stm(1).ResponseAllowed(1)/1000 && ...
                lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
            % correct
            if ~Stm(1).RequireSpecificPaw || Par.NewResponse == Par.PawSides(1)
                Par.RespValid = true;
                Par.CurrResponse = RESP_CORRECT;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    % NewResponse indicates left or right responses
                    Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
                        Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
                    Par.CorrectThisTrial = true;
                    Par.ManResp4Log = Par.NewResponse;
                    resp_time = 1000*(lft - Par.SwitchStart) + Stm(1).ResponseAllowed(1);
                    % fprintf('Response time: %0.f ms\n', resp_time);
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~Stm(1).RequireSpecificPaw || Par.NewResponse ~= Par.PawSides(1)
                % false
                Par.RespValid = false;
                Par.CurrResponse = RESP_FALSE;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    
                    % NewResponse indicates left or right responses
                    Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
                        Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
                    Par.CorrectThisTrial = false;
                    Par.ResponseGiven=true;
                    Par.ManResp4Log = Par.NewResponse;
                end
                Par.FalseResponseGiven=true;
                if Stm(1).BreakOnFalseHit
                    Par.BreakTrial=true;
                end
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
            Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
                Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
            Par.CorrectThisTrial = false;
            Par.ManResp4Log = Par.NewResponse;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
        elseif ~Par.FixIn && Par.RequireFixation
            % false
            Par.CurrResponse = RESP_BREAK_FIX;
            Par.RespValid = false;
            if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                %Par.ResponsePos
                Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
                    Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
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
        %DrawFix;
        %DrawStimuli; % update lifted paw indicator
        % >> WHY? will be done on next iteration
        
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
        
        if Par.FalseResponseGiven && ...
                Stm(1).FalseHitRewardRatio > 0 && ...
                Stm(1).AutoReward && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
    
    if Par.CurrResponse > 0 && ...
            isfield(Par, 'FeedbackSound') && ...
            isfield(Par, 'FeedbackSoundPar') && ...
            Par.FeedbackSound(Par.CurrResponse) && ...
            all(~isnan(Par.FeedbackSoundPar(Par.CurrResponse,:)))
        if Par.FeedbackSoundPar(Par.CurrResponse)
            try
               % fprintf('trying to play a sound\n')
                PsychPortAudio('Start', ...
                    Par.FeedbackSoundSnd(Par.CurrResponse).h, 1, 0, 1);
            catch
            end
        end
    end
    
    % switch to orientation 1
    Par.DrawPawIndNow = false;
    Par.CurrOrient=1;
    
    %% POSTSWITCH ---------------------------------------------------------
    Par.State='POSTSWITCH';
    Par.PostSwitchStart=lft;
    
    while lft < Par.PostSwitchStart + ...
            Stm(1).EventPeriods(3)/1000 && ~Par.PosReset && ...
            ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli -----------------------------------------------------
        DrawStimuli;
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses -------------------------------------------
        CheckKeys; % internal function
        
        % check for manual responses --------------------------------------
        CheckManual;
        if Par.NewResponse && ...
                lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
            
            % correct
            if ~Stm(1).RequireSpecificPaw || Par.NewResponse == Par.PawSides(1)
                Par.RespValid = true;
                Par.CurrResponse = RESP_CORRECT;
                if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    Par.CorrectThisTrial=true;
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~Stm(1).RequireSpecificPaw || Par.NewResponse ~= Par.PawSides(1)
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
        
        if Par.FalseResponseGiven && Stm(1).FalseHitRewardRatio > 0 ...
                && Stm(1).AutoReward && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
        
    end
    Par.DrawPawIndNow = false;
    % no response or fix break during switch = miss
    % ~Par.ResponseGiven && ~Par.FalseResponseGiven && ...
    if Par.CurrResponse == RESP_NONE
        Par.CurrResponse = RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
        if Par.CurrResponse > 0 && ...
                isfield(Par, 'FeedbackSound') && ...
                isfield(Par, 'FeedbackSoundPar') && ...
                Par.FeedbackSound(Par.CurrResponse) && ...
                all(~isnan(Par.FeedbackSoundPar(Par.CurrResponse,:)))
            if Par.FeedbackSoundPar(Par.CurrResponse)
                try
                    % fprintf('trying to play a sound\n')
                    PsychPortAudio('Start', ...
                        Par.FeedbackSoundSnd(Par.CurrResponse).h, 1, 0, 1);
                catch
                end
            end
        end
    end
    Par.LastResponse = Par.CurrResponse;
    
    % Consolatory reward --------------------------------------------------
    if ~Par.AutoRewardGiven && ~Par.FalseResponseGiven && ...
            (Par.RequireFixation && rand() < Stm(1).ProbFixationReward && ...
            Par.FixIn || ...
            ~Par.RequireFixation && rand() < Stm(1).ProbConsolatoryReward ...
            ) && ~Par.Paused
        GiveRewardManual;
        Par.ManualReward=false;
        ConsolatoryRewardTime = lft;
    elseif GetSecs > Par.LastRewardTime && ...
            Par.LastRewardTime + Par.MaxTimeBetweenRewardsSecs < GetSecs % give reward if its been 2 minutes
        t = GetSecs;
        GiveRewardManual;
        ConsolatoryRewardTime = lft;
    end
    
    if Stm(1).DisplayChosenTargetDur > 0 && Par.TrialResponse
        Par.DisplayChosenStartTime=lft;
        % Par.NewResponse == Par.PawSides(1)
        which_side = Par.TrialResponse;
        DrawTarget(1.0, 0, which_side);
        
        while lft < Par.DisplayChosenStartTime + ...
                Stm(1).DisplayChosenTargetDur/1000 && ~Par.ESC
            CheckKeys; % internal function
            DrawTarget(1.0, 0, which_side);
            
            % allow manual reward
            if Par.ManualReward
                GiveRewardManual;
                Par.ManualReward=false;
            end
            DrawLiftedResponseIndicators;
            lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        end
    end
    
    %% ITI ----------------------------------------------------------------
    Par.State='ITI';
    Par.ITIStart=lft;
    
    while lft < Par.ITIStart + ...
            Stm(1).ITI/1000 && ~Par.PosReset && ...
            ~Par.ESC && ~Par.BreakTrial
        
        Par.DrawPawIndNow = false;
        
        % DrawStimuli
        DrawStimuli;
        
        % Check eye fixation ----------------------------------------------
        CheckFixation;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
%         if Par.NewResponse
%             % false hit / early response
%             Par.RespValid = false;
%             Par.CurrResponse = RESP_EARLY;
%             Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
%             Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
%             
%             % NewResponse indicates left or right responses
%             Par.ManResp4Log = Par.NewResponse;
%             Par.ResponseSide(Par.NewResponse, Par.CurrResponse) = ...
%                 Par.ResponseSide(Par.NewResponse, Par.CurrResponse)+1;
%             Par.FalseResponseGiven=true;
%             Par.RespTimes=[Par.RespTimes;
%                 lft-Par.ExpStart Par.RespValid];
%             if Stm(1).BreakOnFalseHit
%                 Par.BreakTrial=true;
%             end
%         elseif ~Par.FixIn && Par.RequireFixation
%             % false
%             Par.RespValid = false;
%             Par.CurrResponse = RESP_BREAK_FIX;
%             Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
%             Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
%             Par.FalseResponseGiven=false;
%             Par.BreakTrial=true;
%         end
        
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
    
    %% Break for false hit ------------------------------------------------
    if Par.BreakTrial
        Par.BreakStartTime=lft;
        %fprintf('Getting a time penalty...\n');
       
        while lft < Par.BreakStartTime + ...
                (Stm(1).BreakDuration+Stm(1).ITI)/1000 && ~Par.ESC
            CheckManual;
            CheckKeys; % internal function
            DrawNoiseOnly;
            
            % give manual reward
            if Par.ManualReward
                GiveRewardManual;
                Par.ManualReward=false;
            end
        end
    end
    
    %% Performance info on screen -----------------------------------------
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
    
    %% Display total reward every x correct trials
    if Par.CurrResponse == RESP_CORRECT && ...
            mod(Par.Response(RESP_CORRECT),10) == 0 && ...
            Par.Response(RESP_CORRECT) > 0 && ...
            isfield(Stm(1),'TaskName')
        
        fprintf(['\nTask: ' Stm(1).TaskName(Stm(1).Task) '\n']);
        
        
        Log.TCMFR = [Log.TCMFR; ...
            Par.Trlcount(2) ...
            Par.Response(1) ...
            Par.Response(3) ...
            Par.Response(2) ...
            Log.TotalReward];
        fprintf(['Paw accuracy (block): ',...
            num2str( round(100 * ...
            Par.ResponsePos(RESP_CORRECT)/...
            (Par.ResponsePos(RESP_CORRECT) + ...
            Par.ResponsePos(RESP_FALSE))))])
        fprintf(['%%\t (total): ',...
            num2str( round(100 * ...
            Par.Response(RESP_CORRECT)/...
            (Par.Response(RESP_CORRECT) + ...
            Par.Response(RESP_FALSE))))...
            '%%\n\n'])
        
        % Check if should automatically cycle
        if Par.AutoCycleTasks
            RecentRatioCorrect = (Par.ResponsePos(RESP_CORRECT))/...
                (Par.ResponsePos(RESP_CORRECT) + ...
                Par.ResponsePos(RESP_FALSE));
            Par.MinRatioCorrectToChangeTask = 0.7;
            if RecentRatioCorrect >= Par.MinRatioCorrectToChangeTask
                Stm(1).TaskCycleInd = mod( Stm(1).TaskCycleInd, ...
                    size(Stm(1).TasksToCycle, 2)) + 1;
                Stm(1).Task = Stm(1).TasksToCycle(Stm(1).TaskCycleInd);
                Par.TaskSwitched = true;
                fprintf(['Automatically cycling task to ' Stm(1).TaskName(Stm(1).Task) '\n']);
            else
                fprintf(['Not automatically cycling due to poor performance ('...
                    num2str(round(RecentRatioCorrect*100)) ...
                    '%%  correct, must be ' ...
                    num2str(Par.MinRatioCorrectToChangeTask*100) ...
                    '%% correct)'])
            end
            if ~Par.RequireFixation
                Par.RequireFixation = true;
                fprintf('Requiring fixation (auto).\n');
            end
        end
        
        % reset
        Par.ResponsePos = 0*Par.ResponsePos;
    end
    
    %% LOG TRIAL INFO -----------------------------------------------------
    Log.Trial(Par.Trlcount(2)).TrialNr = Par.Trlcount(2);
    Log.Trial(Par.Trlcount(2)).PosNr = Par.PosNr;
    Log.Trial(Par.Trlcount(2)).TrialNrPos = Par.Trlcount(1);
    Log.Trial(Par.Trlcount(2)).PreSwitchStart = ...
        Par.PreSwitchStart-Par.ExpStart;
    Log.Trial(Par.Trlcount(2)).SwitchStart = ...
        Par.SwitchStart-Par.ExpStart;
    Log.Trial(Par.Trlcount(2)).PostSwitchStart = ...
        Par.PostSwitchStart-Par.ExpStart;
    if Par.ResponseGiven
        Log.Trial(Par.Trlcount(2)).RespTime = Par.RespTimes(end,1);
    else
        Log.Trial(Par.Trlcount(2)).RespTime = nan;
    end
    Log.Trial(Par.Trlcount(2)).Reward = Par.AutoRewardGiven;
    Log.Trial(Par.Trlcount(2)).RewardAmount = Par.RewardTime;
    Log.Trial(Par.Trlcount(2)).ManualRewards = Par.ManRewThisTrial;
    
    Log.Trial(Par.Trlcount(2)).ResponseGiven = Par.ResponseGiven;
    Log.Trial(Par.Trlcount(2)).CurrResponse = Par.CurrResponse;
    Log.Trial(Par.Trlcount(2)).CorrectThisTrial = Par.CorrectThisTrial;
    Log.Trial(Par.Trlcount(2)).RespSideIndicator = Par.PawSides(1); % Which button indicator is on the screen
    Log.Trial(Par.Trlcount(2)).RespSide = Par.ManResp4Log; % Which button was lifted
    
    %% Switch position if required to do this automatically
    if Par.ToggleCyclePos && Stm(1).CyclePosition && ...
            Log.Trial(Par.Trlcount(2)).TrialNrPos >= Stm(1).CyclePosition
        % next position
        Par.SwitchPos = true;
        Par.WhichPos = 'Next';
        ChangeStimulus;
        Par.SwitchPos = false;
    end
    
    %% Update Tracker window
    if ~TestRunstimWithoutDAS
        %SCNT = {'TRIALS'};
        SCNT(1) = { ['C:' num2str(Par.Response(RESP_CORRECT)) ...
            ' ' num2str(Par.ResponseSide(1, RESP_CORRECT)) '+' num2str(Par.ResponseSide(2, RESP_CORRECT)) ] };
        SCNT(2) = { ['F:' num2str(Par.Response(RESP_FALSE)) ...
            ' ' num2str(Par.ResponseSide(1, RESP_FALSE)) '+' num2str(Par.ResponseSide(2, RESP_FALSE)) ] };
        SCNT(3) = { ['M:' num2str(...
            Par.Response(RESP_MISS)+ ... %Par.Response(RESP_EARLY)+ ...
            Par.Response(RESP_BREAK_FIX)) '   E:' num2str(Par.Response(RESP_EARLY)) ]};
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
% Empty the screen
Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);

% close audio devices
for i=1:length(Par.FeedbackSoundSnd)
    if ~isnan(Par.FeedbackSoundSnd(i).h)
        PsychPortAudio('Close', Par.FeedbackSoundSnd(i).h);
    end
end

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

%% Standard functions called throughout the runstim =======================
% create fixation window around target ------------------------------------
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
    function DrawTarget(color, offset, which_side, size_pix)
        if nargin < 4
            size_pix = Stm(1).PawIndSizePix;
        end
        if length(color) == 1
            alpha = color;
            color = (...
                (1 - alpha)*Stm(1).BackColor + ...
                Stm(1).PawIndCol(which_side,:) * alpha) * Par.ScrWhite;
        end
        % Fixation position
        hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
        vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
        fix_pos = ...
            [hfix, vfix; ...
            hfix, vfix; ...
            hfix, vfix; ...
            hfix, vfix];
        for define_square=1 % left / square
            lmost=-size_pix/2;
            rmost= size_pix/2;
            tmost=-size_pix/2;
            bmost= size_pix/2;
            left_square = [lmost,tmost; ...
                rmost,tmost; ...
                rmost,bmost; ...
                lmost,bmost ...
                ];
        end
        for define_diamond=1 % right / diamond
            lmost=-sqrt(2)*size_pix/2;
            rmost= sqrt(2)*size_pix/2;
            tmost=-sqrt(2)*size_pix/2;
            bmost= sqrt(2)*size_pix/2;
            right_diamond = [lmost,0; ...
                0,tmost; ...
                rmost,0; ...
                0,bmost ...
                ];
        end
        if which_side==1
            Screen('FillPoly',Par.window,...
                color,...
                fix_pos + left_square + offset);
        else
            Screen('FillPoly',Par.window,...
                color,...
                fix_pos + right_diamond + offset);
        end
    end
% draw stimuli ------------------------------------------------------------
    function DrawStimuli
        % Background ------------------------------------------------------
        Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        
        % Noise patch -----------------------------------------------------
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
        
        % Paw indicators --------------------------------------------------
        if Stm(1).RequireSpecificPaw && Par.DrawPawIndNow
            
            % size
            PawIndSizePix = Stm(1).PawIndSizePix;
            
            % side
            attd_offset = repmat( ...
                Stm(1).PawIndOffsetPix(1,:), [4,1]);
            
            % draw
            if mod(Stm(1).Task, 2) == Stm(1).TASK_FIXED_TARGET_LOCATIONS
                % -------------------- Attend targets away from Fixation Point
                color = (...
                    Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                    Stm(1).PawIndCol(Par.PawSides(1),:) * Par.unattended_alpha) * Par.ScrWhite;
                
                is_side_left = Par.PawSides(1) == 1;
                DrawTarget(color, attd_offset, is_side_left);
                
            elseif mod(Stm(1).Task, 2) == Stm(1).TASK_TARGET_AT_FIX && ...
                    Stm(1).Task < Stm(1).TASK_FIXED_TARGET_LOCATIONS
                % -------------------- Attend targets at Fixation Point
                
                % Everything not at target is distractor
                color0 = (...
                    Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                    Stm(1).TraceCurveCol * Par.unattended_alpha) * Par.ScrWhite;
                
                % connected curve (distractor, since target is at fix)
                
                con_offset = repmat( ...
                    Stm(1).PawIndOffsetPix(Par.DistractLineTarget(1),:), [4,1]);
                
                discon_offset = repmat( ...
                    Stm(1).PawIndOffsetPix(Par.DistractLineTarget(2),:), [4,1]);
                
                if Par.unattended_alpha > 0.0
                    for indpos = 1:Stm(1).NumOfPawIndicators
                        discon_offset = repmat( ...
                            Stm(1).PawIndOffsetPix(indpos,:), [4,1]);
                        
                        DrawCurve(discon_offset, false, false, indpos);
                    end
                    discon_offset = NaN;
                end
                
                color0 = (...
                    Stm(1).BackColor * (1-Par.unattended_alpha) + ...
                    Stm(1).PawIndCol(Par.PawSides(1),:) * Par.unattended_alpha) * Par.ScrWhite;
            else
                % task related curve
                if strcmp(Par.State, 'PRESWITCH')
                    DrawCurve2(attd_offset(1,:), true, true, 1);
                else
                    DrawCurve2(attd_offset(1,:), post_switch_joint_alpha, post_switch_joint_alpha, 1);
                end
                
                if Par.unattended_alpha > 0.0
                    for indpos = 2:Stm(1).NumOfPawIndicators
                        discon_offset = Stm(1).PawIndOffsetPix(indpos,:);
                        
                        DrawCurve2(discon_offset, false, ...
                            ... strcmp(Par.State, 'PRESWITCH') && Par.PartConnectedTarget==indpos,...
                            Par.PartConnectedTarget==indpos,...
                            indpos);
                    end
                    discon_offset = NaN;
                end
                alpha = Stm(1).PawIndAlpha(~strcmp(Par.State, 'PRESWITCH')+1, 1);
                color0 = (...
                    Stm(1).PawIndCol(Par.PawSides(1),:) * ...
                    alpha + ...
                    (1-alpha)*Stm(1).BackColor ...
                    ).*Par.ScrWhite;
            end
            
            % draw differently in pre/post switch phases
            if strcmp(Par.State, 'PRESWITCH')
                % ------------------------------- PRESWITCH
                alpha1 = 1.0 * Par.trial_preswitch_alpha;
                color1 = (...
                    (1 - alpha1)*Stm(1).BackColor + ...
                    Stm(1).PawIndCol(Par.PawSides(1),:) * alpha1) * Par.ScrWhite;
                
                if alpha1 > 0.0
                    DrawTarget(color1, attd_offset, Par.PawSides(1) == 1)
                end
                
                hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
                vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
                fix_pos = ...
                    [hfix, vfix; ...
                    hfix, vfix; ...
                    hfix, vfix; ...
                    hfix, vfix];
                if alpha1 < 1.0
                    DrawPreSwitchFigure(fix_pos(1,:)+attd_offset(1,:), ...
                        PawIndSizePix,...
                        1-Par.trial_preswitch_alpha);
                end
                
                for indpos = 2:Stm(1).NumOfPawIndicators
                    alpha1 = (1-Stm(1).PawIndAlpha(1, indpos)) * ...
                        Par.unattended_alpha * ...
                        Par.trial_preswitch_alpha;
                    
                    discon_offset = repmat( ...
                        Stm(1).PawIndOffsetPix(indpos,:), [4,1]);
                    side = Par.PawSides(indpos);
                    
                    color1 = (...
                        (1 - alpha1)*Stm(1).BackColor + ...
                        Stm(1).PawIndCol(side,:) * alpha1) * Par.ScrWhite;
                    
                    if alpha1 > 0.0 % draw faded out indicator
                        DrawTarget(color1, discon_offset, Par.PawSides(indpos)==1)
                    end
                    
                    if alpha1 < 0.5 % draw ambiguous pre-switch placeholder
                        DrawPreSwitchFigure(fix_pos(1,:)+discon_offset(1,:), ...
                            PawIndSizePix,  ...
                            (1-Par.trial_preswitch_alpha)*Stm(1).PawIndAlpha(1, indpos));
                    end
                end
            else % ------------------------------- POSTSWITCH
                DrawTarget(color0, attd_offset, Par.PawSides(1)==1)
                
                for indpos = 2:Stm(1).NumOfPawIndicators
                    discon_offset = repmat( ...
                        Stm(1).PawIndOffsetPix(indpos,:), [4,1]);
                    side = Par.PawSides(indpos);
                    
                    Color_obj = Stm(1).PawIndCol(side,:) * ...
                        Par.unattended_alpha * ...
                        Stm(1).PawIndAlpha(2, indpos);
                    Color_bg = Stm(1).BackColor * ...
                        (1 - Par.unattended_alpha * ...
                        Stm(1).PawIndAlpha(2, indpos));
                    Unattd_color = (Color_obj + Color_bg) * Par.ScrWhite;
                    
                    DrawTarget(Unattd_color, discon_offset, side==1)
                end
            end
        end
        
        % fixation
        DrawFix;
        
        % curve tracing functionality
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
            
            Screen('DrawLine', Par.window, ...
                Stm(1).TraceCurveCol, hfix, vfix, ...
                hfix, vfix,...
                Stm(1).TraceCurveWidth);
            
            % ------------- Draw Figure at Fixation Point -------------
            
            if strcmp(Par.State, 'PRESWITCH')
                alpha1 = 1.0 * Par.trial_preswitch_alpha;
            else
                alpha1 = 1.0;
            end
            color1 = (...
                [Stm(1).PawIndCol(Par.PawSides(1),1:3),alpha1].*Par.ScrWhite);
            
            % Draw Side Indicator
            
            DrawTarget(color1, 0, Par.PawSides(1) == 1)
            if strcmp(Par.State, 'PRESWITCH')
                DrawPreSwitchFigure(fix_pos, PawIndSizePix, 1-Par.trial_preswitch_alpha)
            end
        end
        
        % Target bar - "Go bar" -------------------------------------------
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
        DrawLiftedResponseIndicators
        
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    end
% draw Noise only ---------------------------------------------------------
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
                %Screen('FillRect',Par.window, [.5 .25 0].*Par.ScrWhite);
            else
                % Dark background
                %Screen('FillRect',Par.window, 0.0 * Par.BG.*Par.ScrWhite);
                %Screen('FillRect',Par.window, [.5 .25 0].*Par.ScrWhite);
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
            % DrawFix;  % <-- Why draw fixation point?
        end
        DrawLiftedResponseIndicators;
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        
    end
% draw fixation -----------------------------------------------------------
    function DrawFix
        fix_pos = Stm(1).Center(Par.PosNr,:)+Par.ScrCenter(:)';
        rect=[...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).FixDotSizePix/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).FixDotSizePix/2];
        if Par.RequireFixation
            % fixation area
            Screen('FillOval',Par.window, Par.CurrFixCol, rect);
        else
            Screen('FillOval',Par.window, Stm(1).FixDotCol(3,:).*Par.ScrWhite, rect);
        end
        % if strcmp(Par.State, 'PRESWITCH') && mod(Stm(1).Task, 2) == Stm(1).TASK_TARGET_AT_FIX
        %   DrawPreSwitchFigure(fix_pos, Stm(1).FixDotSizePix,  1-Par.trial_preswitch_alpha);
        % end
    end
% draw pre-switch figure --------------------------------------------------
    function DrawPreSwitchFigure(pos, SizePix, alpha)
        lmost=-sqrt(1/pi);
        rmost= sqrt(1/pi);
        tmost=-sqrt(1/pi);
        bmost= sqrt(1/pi);
        wait_circle = [lmost, tmost, rmost, bmost];
        color = (1 - alpha)*Stm(1).BackColor + ...
            Stm(1).PawIndCol(3,:).* alpha;
        Screen('FillOval', Par.window, color .*Par.ScrWhite, ...
            repmat(pos(1,:),[1,2]) + wait_circle*SizePix);
    end
% draw curves -------------------------------------------------------------
    function DrawCurve2(pos, connection1, connection2, indpos)
        if ~isfield(Par, 'CurveAngles') || ~isfield(Stm(1), 'BranchDistDeg')
            DrawCurve(pos, connection1, connection2, indpos);
            return;
        end
        npoints = 500;
        distractor = ~(connection1 && connection2);
        hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
        vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
        d1 = sqrt(pos(1)^2 + pos(2)^2);
        
        if mod(Par.CurveAngles(indpos)+90, 360) < 180
            target_angle = 180;
        else
            target_angle = 0;
        end
        pt1 = [ cos(Par.CurveAngles(indpos)*pi/180), ...
            -sin(Par.CurveAngles(indpos)*pi/180)] * ...
            Stm(1).BranchDistDeg * Par.PixPerDeg;
        pt2 = [ cos(Par.CurveAngles(indpos)*pi/180), ...
            -sin(Par.CurveAngles(indpos)*pi/180)] * ...
            Stm(1).CurveTargetDistDeg * Par.PixPerDeg;
        spline_pts = [hfix, vfix; ...
            hfix+pt1(1), vfix+pt1(2);
            hfix+pos(1)-pt2(1), vfix+pos(2)-pt2(2);
            hfix+pos(1), vfix+pos(2)];
        
        pts = bezier_curve_with_lines(spline_pts, round([npoints npoints npoints]/3));
        
        alpha = Stm(1).CurveAlpha(~strcmp(Par.State, 'PRESWITCH')+1, ...
            indpos);
        if connection1 && connection2
            base_alpha = alpha;
            pts_alpha = repmat(base_alpha, [size(pts,1), 1]);
            startpos = 1;
        else
            if connection2 % Small gap to fixation point
                Gap = Stm(1).Gap1_deg(2);
            else % larger gap
                Gap = Stm(1).Gap2_deg(2);
            end
            
            base_alpha = Par.unattended_alpha * alpha;
            pts_alpha = repmat(base_alpha, [size(pts,1), 1]);
            startpos = int16(Gap * size(pts,1));
            
            GD = Gap * Par.PixPerDeg;
            ptD = [0; cumsum(sqrt(diff(pts(:,1)).^2 + diff(pts(:,2)).^2))];
            
            pts_alpha(~connection1 & ...
                ptD >= Stm(1).Gap1_deg(1)*Par.PixPerDeg & ...
                ptD < Stm(1).Gap1_deg(2)*Par.PixPerDeg) = nan;
            pts_alpha(~connection2 & ...
                ptD >= Stm(1).Gap2_deg(1)*Par.PixPerDeg & ...
                ptD < Stm(1).Gap2_deg(2)*Par.PixPerDeg) = nan;
        end
        linecol = [repmat(Stm(1).TraceCurveCol, [size(pts,1) 1]), pts_alpha] * Par.ScrWhite;
        draw_curve_along_pts(Par.window, ...
            pts(:,1), pts(:,2), Stm(1).TraceCurveWidth, linecol);
    end
    function DrawCurve(pos, connection1, connection2, indpos)
        distractor = ~(connection1 && connection2);
        if ~isfield(Stm(1), 'CurveConnectionPosX')
            if ~distractor
                DrawLine(pos, indpos);
            end
            return
        end
        alpha = Stm(1).CurveAlpha(~strcmp(Par.State, 'PRESWITCH')+1, ...
            indpos);
        if connection1 && connection2
            base_alpha = alpha;
        else
            base_alpha = Par.unattended_alpha * alpha;
        end
        hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
        vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
        
        gap = Stm(1).CurveConnectionPosX(1) * pos(1,1);
        joint1 = Stm(1).CurveConnectionPosX(2) * pos(1,1); % start of curve
        joint2 = Stm(1).CurveConnectionPosX(3) * pos(1,1); % midpoint of curve
        joint3 = Stm(1).CurveConnectionPosX(4) * pos(1,1); % end of curve, near target
        
        % left, top, right, bottom
        rect = [hfix + joint1 - (joint2 - joint1), ...
            vfix + pos(1,2), ...
            hfix + joint2, ...
            vfix];
        rect2 = [...
            min(rect(1), rect(3)) - Stm(1).TraceCurveWidth/2, ...
            min(rect(2), rect(4)) - Stm(1).TraceCurveWidth/2, ...
            max(rect(1), rect(3)) + Stm(1).TraceCurveWidth/2, ...
            max(rect(2), rect(4)) + Stm(1).TraceCurveWidth/2 ...
            ];
        
        if connection1
            Screen('DrawLine', Par.window, ...
                [Stm(1).TraceCurveCol connection1*base_alpha] * Par.ScrWhite, ...
                hfix, vfix, ...
                hfix + gap, vfix, ...
                Stm(1).TraceCurveWidth);
        end
        
        Screen('DrawLine', Par.window, ...
            [Stm(1).TraceCurveCol base_alpha] * Par.ScrWhite, ...
            hfix + gap, vfix, ...
            hfix + joint1, vfix, ...
            Stm(1).TraceCurveWidth);
        
        if pos(1,1) < 0
            if pos(1,2) < 0
                angle = 180;
            else
                angle = 270;
            end
        else
            if pos(1,2) < 0
                angle = 90;
            else
                angle = 0;
            end
        end
        if connection2
            angle_diff = 0;
        else
            angle_diff = Stm(1).CurveAngleGap;
        end
        if pos(1,1) * pos(1,2) > 0
            angle_discon = angle_diff;
        else
            angle_discon = 0;
        end
        
        % This is a distracting curve connection
        if ~connection1 && connection2 && Stm(1).Task == Stm(1).TASK_TARGET_AT_CURVE
            % Fill in "gap" with DistractBranchConnAlpha
            Screen('FrameArc', Par.window, ...
                [Stm(1).TraceCurveCol ...
                Stm(1).DistractBranchConnAlpha*connection2*base_alpha] * Par.ScrWhite, ...
                rect2, ...
                angle + angle_discon, 90 - angle_diff,...
                Stm(1).TraceCurveWidth);
            % The non-gap part of curve
            if pos(1,1) * pos(1,2) > 0
                angle_discon = Stm(1).CurveAngleGap;
            else
                angle_discon = 0;
            end
            Screen('FrameArc', Par.window, ...
                [Stm(1).TraceCurveCol connection2*base_alpha] * Par.ScrWhite, ...
                rect2, ...
                angle + angle_discon, 90 - Stm(1).CurveAngleGap,...
                Stm(1).TraceCurveWidth);
        elseif connection2
            Screen('FrameArc', Par.window, ...
                [Stm(1).TraceCurveCol connection2*base_alpha] * Par.ScrWhite, ...
                rect2, ...
                angle + angle_discon, 90 - angle_diff,...
                Stm(1).TraceCurveWidth);
        else
            Screen('FrameArc', Par.window, ...
                [Stm(1).TraceCurveCol base_alpha] * Par.ScrWhite, ...
                rect2, ...
                angle + angle_discon, 90 - angle_diff,...
                Stm(1).TraceCurveWidth);
        end
        
        % left, top, right, bottom
        rect = [hfix + joint2, ...
            vfix + pos(1,2), ...
            hfix + joint3 + (joint3 - joint2), ...
            vfix];
        rect2 = [...
            min(rect(1), rect(3)) - Stm(1).TraceCurveWidth/2, ...
            min(rect(2), rect(4)) - Stm(1).TraceCurveWidth/2, ...
            max(rect(1), rect(3)) + Stm(1).TraceCurveWidth/2, ...
            max(rect(2), rect(4)) + Stm(1).TraceCurveWidth/2 ...
            ];
        Screen('FrameArc', Par.window, ...
            [Stm(1).TraceCurveCol base_alpha] * Par.ScrWhite, ...
            rect2, ...
            angle+180, 90,...
            Stm(1).TraceCurveWidth);
        
        Screen('DrawLine', Par.window, ...
            [Stm(1).TraceCurveCol base_alpha] * Par.ScrWhite, ...
            hfix + joint3,...
            vfix + pos(1,2), ...
            hfix + pos(1,1), ...
            vfix + pos(1,2),...
            Stm(1).TraceCurveWidth);
    end
    function DrawLine(pos, indpos)
        hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
        vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
        alpha = Stm(1).CurveAlpha(~strcmp(Par.State, 'PRESWITCH')+1, ...
            indpos);
        Screen('DrawLine', Par.window, ...
            [Stm(1).TraceCurveCol alpha] * Par.ScrWhite, ...
            hfix, vfix, ...
            hfix + pos(1,1), vfix + pos(1,2), ...
            Stm(1).TraceCurveWidth);
    end
% draw lifted button indicators -------------------------------------------
    function DrawLiftedResponseIndicators
        if isfield(Stm(1), 'LiftedPawIndPositions') && Stm(1).LiftedPawIndSize > 0
            size_pix = Stm(1).LiftedPawIndSize * Par.PixPerDeg;
            if Par.BeamLIsBlocked
                offset = repmat( ...
                    Stm(1).LiftedPawIndPositions(1,:)*Par.PixPerDeg, [4,1]);
                DrawTarget(1.0, offset, 1, size_pix);
            end
            if Par.BeamRIsBlocked
                offset = repmat( ...
                    Stm(1).LiftedPawIndPositions(2,:)*Par.PixPerDeg, [4,1]);
                DrawTarget(1.0, offset, 2, size_pix);
            end
        end
    end
% change stimulus features ------------------------------------------------
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
% check for key-presses ---------------------------------------------------
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
                        case Par.KeyToggleAutoCycleTask
                            if Par.AutoCycleTasks==0
                                Par.AutoCycleTasks = 10;
                                fprintf('Automatic cycling of task type turned ON.\n')
                            else
                                Par.AutoCycleTasks = 0;
                                fprintf('Automatic cycling of task type turned OFF.\n')
                            end
                        case Par.KeyCyclePawSide
                            if Par.PawSides(1)==1
                                Par.PawSides(1)=2;
                            else
                                Par.PawSides(1)=1;
                            end
                            RandomizePawIndOffset();
                            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching; % reset counter
                        case Par.KeyPawSide1
                            Par.PawSides(1)=1;
                            RandomizePawIndOffset();
                        case Par.KeyPawSide2
                            Par.PawSides(1)=2;
                            RandomizePawIndOffset();
                        case Par.KeyCycleTask
                            Stm(1).TaskCycleInd = mod( Stm(1).TaskCycleInd, ...
                                size(Stm(1).TasksToCycle, 2)) + 1;
                            Stm(1).Task = Stm(1).TasksToCycle(Stm(1).TaskCycleInd);
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
                            % case Par.KeyPrevious
                            % Par.SwitchPos = true;
                            % Par.WhichPos = 'Prev';
                        case Par.KeyRequireFixation
                            if ~Par.RequireFixation;
                                Par.RequireFixation = true;
                                fprintf('Requiring fixation.\n')
                            else
                                Par.RequireFixation = false;
                                fprintf('Not requiring fixation.\n')
                            end
                        case Par.KeyDecrPreSwitchAlpha
                            Par.trial_preswitch_alpha = max(0.0, Par.trial_preswitch_alpha - 0.1);
                        case Par.KeyIncrPreSwitchAlpha
                            Par.trial_preswitch_alpha = min(1.0, Par.trial_preswitch_alpha + 0.1);
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
% check DAS for manual responses ------------------------------------------
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
            DrawFix;
            
            % Check eye position
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, ~] = DasCheck;
            end
            
            if Hit == 1 % eye in fix window (hit will never be 1 is tested without DAS)
                Par.FixIn=true;
                Par.LastFixInTime=GetSecs;
                Par.CurrFixCol=Stm(1).FixDotCol(2,:).*Par.ScrWhite;
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
            DrawFix;
            
            % Check eye position
            % DasCheck
            if ~TestRunstimWithoutDAS
                dasrun(5);
                [Hit, ~] = DasCheck;
            end
            
            if Hit == 1 % eye out of fix window
                Par.FixIn=false;
                Par.LastFixOutTime=GetSecs;
                Par.CurrFixCol=Stm(1).FixDotCol(1,:).*Par.ScrWhite;
                refreshtracker(1);
            end
        end
    end
% give automated reward ---------------------------------------------------
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
        
        if Par.FalseResponseGiven
            Par.RewardTimeCurrent = Par.RewardTimeCurrent * Stm(1).FalseHitRewardRatio;
        end
        if isfield(Stm(1), 'TaskRewardMultiplier')
            Par.RewardTimeCurrent = Par.RewardTimeCurrent * ...
                Stm(1).TaskRewardMultiplier(Stm(1).TaskCycleInd);
        end
        if isfield(Stm(1), 'PawRewardMultiplier')
            Par.RewardTimeCurrent = Par.RewardTimeCurrent * ...
                Stm(1).PawRewardMultiplier(Par.TrialResponse);
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
% give manual reward ------------------------------------------------------
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
% check and update eye info in tracker window -----------------------------
    function CheckTracker
        dasrun(5);
        DasCheck;
    end
    function RandomizePawIndOffset
        if Stm(1).Task == Stm(1).TASK_FIXED_TARGET_LOCATIONS || ...
                Stm(1).NumOfPawIndicators <= 1
            % Fixed is a relative term ...
            Stm(1).PawIndOffsetPix = Stm(1).PawIndPositions(Par.PawSides, :) ...
                * Par.PixPerDeg * (1 + (rand(1)-.5)/5);
        else
            % Perform stratisfied repetitions
            % size(Stm(1).PawIndPositions,1) is used to allow right or left
            % branch to appear when there are only 2 targets
            Group_pos = reshape(...
                repmat(randperm(size(Stm(1).PawIndPositions,1)/2, Stm(1).NumOfPawIndicators/2),...
                2,1),...
                [1,Stm(1).NumOfPawIndicators]);
            Group_pos = (Group_pos-1) * 2;
            ind = zeros(size(Group_pos));
            angles = zeros(size(Group_pos));
            for m = 1:Stm(1).NumOfPawIndicators/2
                ind(2*m-1:2*m) = randperm(2);
                
                a = min(Stm(1).CurveAnglesAtFP(m,:));
                b = max(Stm(1).CurveAnglesAtFP(m,:));
                angles(2*m-1:2*m) = (b-a).*rand(1,1) + a;
            end
            Stm(1).PawIndOffsetPix = Stm(1).PawIndPositions(...
                Group_pos + ind, :) * Par.PixPerDeg;
            Par.CurveAngles = angles(Group_pos + ind);
            % Stm(1).PawIndOffsetPix = Stm(1).PawIndPositions(...
            %   randperm(size(Stm(1).PawIndPositions, 1), ...
            %   Stm(1).NumOfPawIndicators), :) * Par.PixPerDeg;
            
            Par.DistractLineTarget = randperm(2);
        end
    end
end
