function runstim(Hnd)
% Updated July 2015 Chris Klink
% Present targets reward eye movement to target
% (take hand position into account)

global Par   %global parameters
global StimObj %stimulus objects
global Log

%% ========================================================================
clc;
%% PriorToDealingWithStimuli

% set PTB priority to max
Par.priorityLevel=MaxPriority(Par.window);
Par.oldPriority=Priority(Par.priorityLevel);

Par.ESC = false; %escape has not been pressed
Log.TotalReward=0;

% re-run parameter-file to update stim-settings without restarting Tracker
eval(Par.PARSETFILE); % can be chosen in menu
DateString_sec = datestr(clock,30);
DateString = DateString_sec(1:end-2);

% output stimsettings filename to cmd
fprintf(['=== Running ' Par.STIMSETFILE ' for ' Par.MONKEY ' ===\n']);
Stm = StimObj.Stm;
fprintf(['Started at ' DateString(1:end-2) '\n']);

% import fixwinsize
Par.FixWinSize = Stm.FixWinSize;

% This control parameter needs to be outside the stimulus loop
FirstEyeRecSet=false;
%dasbit(0,1); %set eye-recording trigger to 1 (=stopped)

% Initial stimulus position is 1
Par.PosNr=1;
Par.PrevPosNr=1;

% Initialize KeyLogging
Par.KeyIsDown=false;
Par.KeyWasDown=false;

% Initialize control parameters
Par.SwitchPos = false;
Par.ToggleCyclePos = false; % overrules the Stim(1)setting; toggles with 'p'
Par.ToggleHideStim = false;
Par.ToggleHideFix = false;
Par.ToggleHideStim2 = false;
Par.ToggleHideFix2 = false;
Par.ManualReward = false;
Par.AutoReward=false;
Par.RewardStarted=false;
Par.RewardRunning=false;
Par.EnterRewDelay=false;

Log.ManualRewardTime = [];
Log.MRI.TriggerReceived=false;

Par.PosReset=false;
Par.Pause=false;

% Initialize photosensor manual response
Par.BeamIsBlocked=false;

%Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite); % black first
% Flip the proper background on screen
%Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
lft=Screen('Flip', Par.window);
lft=Screen('Flip', Par.window, lft+.1);
Par.ExpStart = lft;
Log.nEvents=1;
Log.Events(Log.nEvents).type='ExpStart';
Log.Events(Log.nEvents).t=0;

% Initial stimulus position is 1
Par.PosNr=1;
Par.PrevPosNr=1;

% make sure timing settings are taken from stimsettings once
TimingFromStimsettingsDone=false;
EyeRecMsgShown=false;

%% Run this loop for as many repeats as are defined in the StimSettings ===
nR=0;
while nR<Stm.nRepeatsStimSet && ~Par.ESC
    fprintf(['---- Repetition number ' num2str(nR+1) '----\n']);
    %% PreStim
    nR=nR+1;
    if length(Stm.Cond)>1
        nSTIM=length(Stm.Cond);
        if Stm.RandomizeCond
            StimOrder = randperm(nSTIM);
        else
            StimOrder = 1:nSTIM;
        end
    else
        StimOrder = 1;
    end
    StimOrder_ORG = StimOrder;
    StimDynamic = StimOrder_ORG;
    
    % keep track of how many trials are initiated this repeat
    TrialsStartedThisRep=0;
    TrialsTargThisRep=0;
    TrialsSlowThisRep=0;
    TrialsMissThisRep=0;
    TrialsAbortThisRep=0;
    
    %% InitiateEyetracker
    if Par.EyeRecAutoTrigger
        if ~FirstEyeRecSet
            hmb=msgbox('Prepare the eye-tracker for recording','Eye-tracking');
            uiwait(hmb);
            FirstEyeRecSet=true;
        end
        
        MoveOn=false; MsgShown=false;
        while ~MoveOn
            CheckEyeRecStatus; % checks the current status of eye-recording
            if ~Par.EyeRecStatus % not recording
                SetEyeRecStatus(1); %trigger recording
            else % recording
                SetEyeRecStatus(0);
                pause(0.5);
                SetEyeRecStatus(1);
            end
            
            pause(.2)
            CheckEyeRecStatus; %check whether eye-recording has started
            if Par.EyeRecStatus
                fprintf('Started Eye-signal recording\n\n');
                MoveOn=true;
            else
                if ~MsgShown
                    fprintf('Eye-signal recording won''t start. Check eye-tracker\n');
                    MsgShown=true;
                end
            end
        end
    end
    
    %% Run trials
    while ~isempty(StimDynamic) && ~Par.ESC
        %% Timing ---------------------------------------------------------
        % get values from stimsettings and overwrite intial ones from
        % parsettings
        if ~TimingFromStimsettingsDone % only first time
            Par.Times.ToFix=Stm.PreFixT; % time to enter fixation window
            Par.Times.Fix=Stm.FixT; % time to fix before stim onset
            Par.Times.Targ=Stm.KeepFixT(1); % time to fix before target onset. before 26-9-2014 this was 150
            Par.Times.TargRange=Stm.KeepFixT;
            Par.Times.TargFlashDur=Stm.PreTargFlashDur;
            Par.Times.Stim=Stm.StimT;
            Par.Times.Rt=Stm.ReacT; % max allowed reaction time (leave fixwin after target onset)
            Par.Times.Sacc=Stm.SaccT; % max allowed saccade time (from leave fixwin to enter target win)
            Par.Times.HoldTarg=Stm.HoldTarT; % fixate the target this long
            Par.Times.SaccCorrT = Stm.SaccCorrT;
            Par.Times.Err=Stm.ErrT; % punishment extra ISI after error trial (there are no error trials here)
            Par.Times.ErrT_onEarly = Stm.ErrT_onEarly;
            Par.Times.InterTrial=Stm.ISI; % base inter-stimulus interval
            Par.Times.RndInterTrial=Stm.ISI_RAND; % maximum extra (random) ISI to break any possible rythm
            Par.Times.RewDelay=Stm.RewardDelay;
            
            % update gui fields
            handles=guihandles(Par.hTracker);
            set(handles.ToFixTime, 'String', num2str(Par.Times.ToFix, 4))
            set(handles.FixT, 'String', num2str(Par.Times.Fix, 4))
            set(handles.TargT, 'String', num2str(Par.Times.Targ, 4))
            set(handles.StimT, 'String', num2str(Par.Times.Stim, 4))
            set(handles.ReactionT, 'String', num2str(Par.Times.Rt, 4))
            set(handles.e_Sacc, 'String', num2str(Par.Times.Sacc, 4))
            set(handles.e_Err, 'String', num2str(Par.Times.Err, 4))
            set(handles.InterTT, 'String', num2str(Par.Times.InterTrial, 4))
            
            TimingFromStimsettingsDone=true;
        end
        
        % put into shorter variables (and/or read from gui)
        PREFIXT = Par.Times.ToFix; % time allowed to initiate fixation
        FIXT = Par.Times.Fix; % duration to hold fixation before stimuli appear
        TARGT = Par.Times.Targ; % Duration to hold fixation while stimuli are on the screen
        TARGFLASHDUR =  Par.Times.TargFlashDur;
        STIMT = Par.Times.Stim; % Duration that stim/targets are displayed
        RACT = Par.Times.Rt; % Time allowed to select a target after target onset
        SACCT= Par.Times.Sacc; % Allowed saccade time between leaving fixwin and entering targwin
        ISI = Par.Times.InterTrial; % interstimulus interval
        ISI_R = Par.Times.RndInterTrial; % max random addition to ISI
        HTART = Par.Times.HoldTarg; % fixate the target this long
        SACC_CORR_T = Par.Times.SaccCorrT;
        ERRT = Par.Times.Err; % % punishment addition to ISI after error trial
        % there are no error trials here
        ERRT_ONEARLY = Par.Times.ErrT_onEarly;
        REWDELAY = Par.Times.RewDelay;
        
        %% Prepare stimuli ------------------------------------------------
        CurCond=StimDynamic(1);
        for TargNum=1:length(Stm.Cond(CurCond).Targ)
            Tar(TargNum).Shape = Stm.Cond(CurCond).Targ(TargNum).Shape; %#ok<*AGROW>
            Tar(TargNum).PosPix = Stm.Cond(CurCond).Targ(TargNum).Position*Par.PixPerDeg;
            if strcmp(Tar(TargNum).Shape,'circle')
                Tar(TargNum).SizePix = Stm.Cond(CurCond).Targ(TargNum).Size*Par.PixPerDeg;
                Tar(TargNum).Rot = 0;
            elseif strcmp(Tar(TargNum).Shape,'square')
                Tar(TargNum).SizePix = ...
                    round(sqrt(...
                    ((Stm.Cond(CurCond).Targ(TargNum).Size/2*Par.PixPerDeg).^2)*pi));
                Tar(TargNum).Rot = 0;
            elseif strcmp(Tar(TargNum).Shape,'diamond')
                Tar(TargNum).SizePix = ...
                    round(sqrt(...
                    ((Stm.Cond(CurCond).Targ(TargNum).Size/2*Par.PixPerDeg).^2)*pi));
                Tar(TargNum).Points = [...
                    Par.ScrCenter(1)+Tar(TargNum).PosPix(1)-Tar(TargNum).SizePix/2 ...
                    Par.ScrCenter(2)+Tar(TargNum).PosPix(2); ...
                    Par.ScrCenter(1)+Tar(TargNum).PosPix(1) ...
                    Par.ScrCenter(2)+Tar(TargNum).PosPix(2)-Tar(TargNum).SizePix/2;...
                    Par.ScrCenter(1)+Tar(TargNum).PosPix(1)+Tar(TargNum).SizePix/2 ...
                    Par.ScrCenter(2)+Tar(TargNum).PosPix(2); ...
                    Par.ScrCenter(1)+Tar(TargNum).PosPix(1) ...
                    Par.ScrCenter(2)+Tar(TargNum).PosPix(2)+Tar(TargNum).SizePix/2;...\
                    Par.ScrCenter(1)+Tar(TargNum).PosPix(1)-Tar(TargNum).SizePix/2 ...
                    Par.ScrCenter(2)+Tar(TargNum).PosPix(2)];
            end
            Tar(TargNum).Rect = [...
                Par.ScrCenter(1)+Tar(TargNum).PosPix(1)-Tar(TargNum).SizePix/2 ...
                Par.ScrCenter(2)+Tar(TargNum).PosPix(2)-Tar(TargNum).SizePix/2 ...
                Par.ScrCenter(1)+Tar(TargNum).PosPix(1)+Tar(TargNum).SizePix/2 ...
                Par.ScrCenter(2)+Tar(TargNum).PosPix(2)+Tar(TargNum).SizePix/2 ];
            Tar(TargNum).WinSizePix = Stm.Cond(CurCond).Targ(TargNum).WinSize*Par.PixPerDeg;
            Tar(TargNum).Color = Stm.Cond(CurCond).Targ(TargNum).Color.*Par.ScrWhite;
            Tar(TargNum).RewardGain = Stm.Cond(CurCond).Targ(TargNum).RewardGain;
            Tar(TargNum).PreTargCol = Stm.Cond(CurCond).Targ(TargNum).PreTargCol.*Par.ScrWhite;
            
            Tar(TargNum).RewDel_LW = round(...
                Stm.Cond(CurCond).Targ(TargNum).RewDelayOutlineWidth * Par.PixPerDeg);
        end
        
        %% Prepare fix dot ------------------------------------------------
        Stm.FixWinSizePix = [...
            round(Par.FixWdDeg.*Par.PixPerDeg) ...
            round(Par.FixHtDeg.*Par.PixPerDeg)];
        Stm.FixDotSizePix = round(Stm.FixDotSize*Par.PixPerDeg);
        
        Stm.Center =[];
        for i=1:size(Stm.Position,2)
            Stm.Center =[Stm.Center;round(Stm.Position{i}.*Par.PixPerDeg)];
        end
        
        %% Prepare control windows ----------------------------------------
        DefineEyeWin(Tar)
        refreshtracker(1) %for your control display: update with windows
        SetWindowDas      %for the dascard
        
        %% Initialize control stuff ---------------------------------------
        Log.MRI.TriggerTime = [];
        % Some intitialization of control parameters
        if Par.MRITriggeredStart && ~Log.MRI.TriggerReceived
            if Par.MRITrigger_OnlyOnce && nR==1
                Log.MRI.TriggerReceived = false;
            elseif Par.MRITrigger_OnlyOnce && nR > 1
                Log.MRI.TriggerReceived = true;
            elseif ~Par.MRITrigger_OnlyOnce
                Log.MRI.TriggerReceived = false;
            end
        else % act as if trigger has been received
            Log.MRI.TriggerReceived = true;
        end
        
        % Wait for MRI trigger to allow er-fMRI ---------------------------
        if Par.MRITriggeredStart && ~Log.MRI.TriggerReceived
            fprintf('Waiting for MRI trigger (or press ''t'' on keyboard)\n');
            while ~Log.MRI.TriggerReceived
                CheckKeys;
                Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
                lft=Screen('Flip', Par.window);
            end
            if Par.MRITrigger_OnlyOnce && Par.Trlcount > 0
                %fprintf('Triggering only once, move on automatically now.\n');
            else
                fprintf(['Trigger received after ' num2str(lft-Par.ExpStart) ' s\n\n']);
            end
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='MRITrigger';
            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
        end
        
        %% TRIAL LOOP =====================================================
        TrialStarted=false;
        TrialEnded=false;
        while ~Par.ESC && ~TrialEnded
            % pick a hold-fix time from the specified range
            TARGT=round(normrnd(Par.Times.TargRange(1),Par.Times.TargRange(2)));
            while TARGT <= Par.Times.TargRange(1)-Par.Times.TargRange(2) || ...
                    TARGT >= Par.Times.TargRange(1)+Par.Times.TargRange(2)
                TARGT = round(normrnd(Par.Times.TargRange(1),Par.Times.TargRange(2)));
            end
            STIMT = RACT + TARGT + HTART;
            ERR_ISI = 0;
            
            %% /////////// START THE TRIAL ////////////////////////////////
            Abort = false;    %whether subject has aborted before end of trial
            
            %% //////// EVENT 0 START FIXATING/////////////////////////////
            Par.CurrFixCol = Stm.FixDotCol(1,1:3).*Par.ScrWhite;
            DrawBackground;
            DrawFix;
            lft=Screen('Flip', Par.window);
            StartFixDot=lft;
            
            dasreset(0);   %test enter fix window
            %     0 enter fix window
            %     1 leave fix window
            %     2 enter target window
            
            Par.SetZero = false; %set key to false to remove previous presses
            %Par.Updatxy = 1; %centering key is enabled
            Time = 1; Hit = 0;
            
            while Time < PREFIXT && Hit == 0
                dasrun(5);
                [Hit Time] = DasCheck; %#ok<*NCOMMA> %retrieve position values and plot on Control display
                CheckKeys; %check key presses
                CheckManual; %check status of the photo amp
                ControlReward; % switch reward on or off;
                ChangeFixPos;
                ControlVisibility(Tar,[1 0]);
                if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                    Hit=0;
                end
            end
            
            %% ///////// EVENT 1 KEEP FIXATING or REDO  ///////////////////
            if Hit ~= 0  %subjects eyes are in fixation window keep fixating for FIX time
                dasreset(1);     %set test parameters for exiting fix window
                Time = 1; Hit = 0;
                while Time < FIXT && Hit== 0
                    dasrun(5);
                    [Hit Time] = DasCheck; %retrieve eyechannel buffer and events, plot eye motion,
                    CheckKeys; %check key presses
                    CheckManual; %check status of the photo amp
                    ControlReward; % switch reward on or off;
                    ChangeFixPos;
                    ControlVisibility(Tar,[1 0]);
                    if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                        Hit=-1;
                    end
                end
                
                if Hit ~= 0
                    %eye has left fixation too early or hand is out box
                    %possibly due to eye overshoot, give another chance
                    dasreset(0);
                    Time = 1; Hit = 0;
                    while Time < PREFIXT && Hit == 0
                        dasrun(5)
                        [Hit Time] = DasCheck; %retrieve position values and plot on Control display
                        CheckKeys; %check key presses
                        CheckManual; %check status of the photo amp
                        ControlReward; % switch reward on or off;
                        ChangeFixPos;
                        ControlVisibility(Tar,[1 0]);
                        if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                            Hit=0;
                        end
                    end
                    if Hit ~= 0  %subjects eyes are in fixation window keep fixating for FIX time
                        dasreset( 1); %test for exiting fix window
                        Time = 1; Hit = 0;
                        while Time < FIXT && Hit == 0
                            dasrun(5)
                            [Hit Time] = DasCheck;
                            CheckKeys; %check key presses
                            CheckManual; %check status of the photo amp
                            ControlReward; % switch reward on or off;
                            ChangeFixPos;
                            ControlVisibility(Tar,[1 0]);
                            if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                                Hit=-1;
                            end
                        end
                    else
                        Hit = -1; %the subject did not fixate
                    end
                end
            else
                Hit = -1; %the subject did not fixate
            end
            
            % in case of no fixation: stick with this trial
            % requires no action
            
            %% ///////// EVENT 2 DISPLAY STIMULUS /////////////////////////
            if Hit == 0
                Par.Trlcount = Par.Trlcount + 1; %counts total number of trials for this session
                % if mod(Par.Trlcount,25)==0 || Par.Trlcount==1
                %   fprintf(['Started trial ' num2str(Par.Trlcount) '\n']);
                % end
                TrialStarted = true;
                TrialsStartedThisRep = TrialsStartedThisRep+1;
                
                if TARGT > 0
                    PreTarLogDone = false;
                    
                    % check for breaking fixation
                    dasreset(1); %test for exiting fix window
                    refreshtracker(2)
                    Time = 0;
                    
                    while Time < TARGT  && Hit == 0
                        DrawBackground;
                        if TARGFLASHDUR > 0 && Time < TARGFLASHDUR
                            DrawTargets(Tar,[]);
                        else
                            DrawPreTargets(Tar);
                        end
                        Par.CurrFixCol = Stm.FixDotCol(1,1:3).*Par.ScrWhite;
                        DrawFix;
                        
                        lft=Screen('Flip', Par.window);
                        StimStart=lft;
                        
                        if ~PreTarLogDone
                            % Log trial specs ----
                            Log.Trial(Par.Trlcount).CondNr = CurCond;
                            Log.Trial(Par.Trlcount).StimStart = StimStart;
                            Log.Trial(Par.Trlcount).Timing = Par.Times;
                            PreTarLogDone = true;
                        end
                        
                        %Keep fixating till target onset
                        dasrun(5)
                        [Hit Time] = DasCheck;
                        if Hit && ERRT_ONEARLY
                            ERR_ISI = ERRT;
                            break
                        end
                        CheckKeys; %check key presses
                        CheckManual; %check status of the photo amp
                        ControlReward; % switch reward on or off;
                        ChangeFixPos;
                        ControlVisibility(Tar,[1 1]);
                        if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                            Hit=-1;
                            Abort=true;
                        end
                    end
                    
                end
                
                %% ///////// EVENT 3 TARGET ONSET, REACTION TIME //////////
                if Hit == 0 %subject kept fixation, subject may make an eye movement
                    DrawBackground;
                    DrawTargets(Tar,[]);
                    if ~Stm.FixRemoveOnGo
                        Par.CurrFixCol = Stm.FixDotCol(2,1:3).*Par.ScrWhite;
                        DrawFix;
                    end
                    lft=Screen('Flip', Par.window);
                    TargStart=lft;
                    
                    % Log trial timing
                    Log.Trial(Par.Trlcount).TargStart = TargStart;
                    
                    if TARGT == 0
                        refreshtracker(2);
                        StimStart=lft;
                        % Log trial specs ----
                        Log.Trial(Par.Trlcount).CondNr = CurCond;
                        Log.Trial(Par.Trlcount).StimStart = StimStart;
                        Log.Trial(Par.Trlcount).Timing = Par.Times;
                    end
                    
                    % Record response -------------------------------------
                    dasreset(2); %check target window  enter
                    refreshtracker(3) %set fix point to green
                    
                    % While time is < REACT and < STIM ON
                    Time = 0;
                    while Time < RACT && Time < STIMT-TARGT && Hit <= 0 && ...
                            (~Par.StimNeedsHandInBox || ...
                            (Par.StimNeedsHandInBox && Par.BeamIsBlocked))
                        dasrun(5)
                        [Hit Time] = DasCheck;
                        CheckKeys; %check key presses
                        CheckManual; %check status of the photo amp
                        ControlReward; % switch reward on or off;
                        ChangeFixPos;
                        ControlVisibility(Tar,[1 1]);
                    end
                    
                    % if allowed reaction time surpasses stimpresentation
                    % duration or vice versa ------------------------------
                    if RACT > STIMT-TARGT % switch stim off keep sampling for response
                        DrawBackground;
                        if ~Stm.FixRemoveOnGo
                            Par.CurrFixCol = Stm.FixDotCol(2,1:3).*Par.ScrWhite;
                            DrawFix;
                        end
                        lft=Screen('Flip', Par.window); %#ok<*NASGU>
                        
                        while Time < RACT && Hit <= 0 && ...
                                (~Par.StimNeedsHandInBox || ...
                                (Par.StimNeedsHandInBox && Par.BeamIsBlocked))
                            dasrun(5)
                            [Hit Time] = DasCheck;
                            CheckKeys; %check key presses
                            CheckManual; %check status of the photo amp
                            ControlReward; % switch reward on or off;
                            ChangeFixPos;
                            ControlVisibility(Tar,[1 1]);
                        end
                    elseif   RACT < STIMT-TARGT % switch targ status off keep sampling for response
                        DrawBackground;
                        DrawTargets(Tar,[]);
                        if ~Stm.FixRemoveOnGo
                            Par.CurrFixCol = Stm.FixDotCol(2,1:3).*Par.ScrWhite;
                            DrawFix;
                        end
                        lft=Screen('Flip', Par.window);
                        
                        while Time < STIMT-TARGT && Hit <= 0 && ...
                                (~Par.StimNeedsHandInBox || ...
                                (Par.StimNeedsHandInBox && Par.BeamIsBlocked))
                            dasrun(5)
                            [TooSlowHit Time] = DasCheck;
                            CheckKeys; %check key presses
                            CheckManual; %check status of the photo amp
                            ControlReward; % switch reward on or off;
                            ChangeFixPos;
                            ControlVisibility(Tar,[1 1]);
                        end
                    end
                else
                    Abort = true;
                    Log.Trial(Par.Trlcount).TargStart = [];
                end %END EVENT 3
            else
                Abort = true;
            end %END EVENT 2
            
            %% ///////// POSTTRIAL AND REWARD /////////////////////////////
            if Hit ~= 0 && ~Abort %has entered a target window
                %printf(['HIT is ' num2str(Hit) '\n']);
                if Par.Mouserun
                    HP = line('XData', Par.ZOOM * (LPStat(2) + Par.MOff(1)),...
                        'YData', Par.ZOOM * (LPStat(3) + Par.MOff(2)));
                else
                    HP = line('XData', Par.ZOOM * LPStat(2), 'YData', Par.ZOOM * LPStat(3));
                end
                set(HP, 'Marker', '+', 'MarkerSize', 20, 'MarkerEdgeColor', 'm');
                              
                %% ////// hold target fixation  ///////////////////////////
                ValidResponse = true;
                TargChoice = Hit;
                Par.WIN_prehold = Par.WIN;
                ChoiIdx = Par.WIN(5,:)==TargChoice;
                Par.WIN(5,ChoiIdx) = 0; % make chosen target the new fixation
                Par.WIN(5,1) = TargChoice; % make fixation the chosen target (not useful but needs assignment)
                refreshtracker(1) % for your control display: update with windows
                SetWindowDas      % for the dascard
                
                % only draw the selected target (remove non-selected)
                DrawBackground;
                DrawTargets(Tar,TargChoice);
                if ~Stm.FixRemoveOnGo
                    Par.CurrFixCol = Stm.FixDotCol(2,1:3).*Par.ScrWhite;
                    DrawFix;
                end
                lft=Screen('Flip', Par.window);
                                
                % check whether eye leaves target window
                dasreset(1);     %set test parameters for exiting fix window
                Time = 1; Hit = 0;
                while Time < HTART && Hit == 0
                    dasrun(5);
                    [Hit Time] = DasCheck; %retrieve eyechannel buffer and events, plot eye motion,
                    CheckKeys; %check key presses
                    CheckManual; %check status of the photo amp
                    ControlReward; % switch reward on or off;
                    ChangeFixPos;
                    ControlVisibility(Tar,[1 0]);
                    if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                        Hit=-1;
                    end
                end
                if Hit ~= 0
                    ValidResponse = false;
                    %eye has left fixation too early or hand is out box
                    %possibly due to eye overshoot, give another chance
                    dasreset(0);
                    Time = 1; Hit = 0;
                    while Time < SACC_CORR_T && Hit == 0
                        dasrun(5)
                        [Hit Time] = DasCheck; %retrieve position values and plot on Control display
                        CheckKeys; %check key presses
                        CheckManual; %check status of the photo amp
                        ControlReward; % switch reward on or off;
                        ChangeFixPos;
                        ControlVisibility(Tar,[1 0]);
                        if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                            Hit=0;
                        end
                    end
                    if Hit ~= 0  % subjects eyes are back in fixation window
                        dasreset( 1); %test for exiting fix window
                        Time = 1; Hit = 0;
                        while Time < HTART && Hit == 0
                            dasrun(5)
                            [Hit Time] = DasCheck;
                            CheckKeys; %check key presses
                            CheckManual; %check status of the photo amp
                            ControlReward; % switch reward on or off;
                            ChangeFixPos;
                            ControlVisibility(Tar,[1 0]);
                            if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
                                Hit=-1;
                            end
                        end
                        if Hit == 0
                            ValidResponse = true;
                        end
                    else
                        Hit = -1; %the subject did not fixate target
                    end
                end
                % reset eye windows
                Par.WIN = Par.WIN_prehold;
                Hit = TargChoice;
         
                % Check the response
                if Hit > 0 && LPStat(5) < SACCT && ValidResponse % target 1 within max allowed saccade time
                    TrialStatus=['Target_' num2str(Hit)];
                    TrialsTargThisRep=TrialsTargThisRep+1;
                    Par.Corrcount = Par.Corrcount + 1; %log correct trials
                    Par.RewardTimeTarg = Tar(Hit).RewardGain*Par.RewardTime;
                    Par.TarChosen = Hit;
                    Par.EnterRewDelay = true;
                    %Par.AutoReward=true;
                    
                    % Log which target was chosen
                    Log.Trial(Par.Trlcount).Aborted = false;
                    Log.Trial(Par.Trlcount).TargChosen = Par.TarChosen;
                    Log.TotalReward=Log.TotalReward+Par.RewardTimeTarg;
                    
                    StimDynamic(1)=[];

                elseif Hit ~= 0 && LPStat(5) >= SACCT % too slow
                    TrialStatus='SaccadeTooSlow';
                    Par.Slowcount=Par.Slowcount+1;
                    TrialsSlowThisRep=TrialsSlowThisRep+1;
                    
                    Log.Trial(Par.Trlcount).Aborted = false;
                    if Hit==1
                        Log.Trial(Par.Trlcount).TargChosen = 2;
                    else
                        Log.Trial(Par.Trlcount).TargChosen = 1;
                    end
                elseif ~ValidResponse 
                    TrialStatus='NoTargetFixation';
                end
                
                %keep following eye motion to plot complete saccade
                for i = 1:10   %keep targoff for 50ms
                    daspause(5);
                    DasCheck; %keep following eye motion
                end
                
                % log some behavioral info --------------------
                Log.Trial(Par.Trlcount).ReactTime = LPStat(4);
                Log.Trial(Par.Trlcount).SaccTime = LPStat(5);
                Log.Trial(Par.Trlcount).HitPos = [LPStat(2) LPStat(3)];
                Log.Trial(Par.Trlcount).Status = TrialStatus;
                Log.Trial(Par.Trlcount).TotRew = Log.TotalReward;
            
            elseif Par.Trlcount>0 && ~Abort
                % trial was not aborted but no target was selected in time
                TrialStatus='NoHit';
                Par.Misscount=Par.Misscount+1;
                TrialsMissThisRep=TrialsMissThisRep+1;
                
                % log some behavioral info
                Log.Trial(Par.Trlcount).Aborted = false;
                Log.Trial(Par.Trlcount).TargChosen = 0;
                Log.Trial(Par.Trlcount).ReactTime = [];
                Log.Trial(Par.Trlcount).SaccTime = [];
                Log.Trial(Par.Trlcount).HitPos = [];
                Log.Trial(Par.Trlcount).Status = TrialStatus;
                Log.Trial(Par.Trlcount).TotRew = Log.TotalReward;
                
                StimDynamic(1)=[];
                
            elseif Par.Trlcount>0 && TrialStarted && Abort
                % trial was started but aborted
                TrialStatus='Aborted';
                TrialsAbortThisRep=TrialsAbortThisRep+1;
                Log.Trial(Par.Trlcount).Aborted = true;
                Log.Trial(Par.Trlcount).TargChosen = 0;
                
                % log some behavioral info
                Log.Trial(Par.Trlcount).ReactTime = [];
                Log.Trial(Par.Trlcount).SaccTime = [];
                Log.Trial(Par.Trlcount).HitPos = [];
                Log.Trial(Par.Trlcount).Status = TrialStatus;
                Log.Trial(Par.Trlcount).TotRew = Log.TotalReward;
                
                % put trial number back in list in defined way
                if Par.Drum
                    if Par.DrumType == 1
                        % stick with trial, no action required
                    elseif Par.DrumType == 2
                        StimDynamic = [StimDynamic(2:end) StimDynamic(1)];
                    elseif Par.DrumType == 3
                        % put it in a random location
                        sl=ceil(rand(1)*length(StimDynamic));
                        StimDynamic=[StimDynamic StimDynamic(sl)];
                        StimDynamic(sl)=StimDynamic(1);
                        StimDynamic(1)=[];
                    end
                else
                    StimDynamic(1)=[];
                end
            end
            dasrun(5);
            [Hit Lasttime] = DasCheck;
            
            %% ///////// REWARD DELAY /////////////////////////////
            if Par.EnterRewDelay
                DrawBackground;
                DrawRewDelayIndicator(Tar,Par.TarChosen);
                lft=Screen('Flip', Par.window);
                REWDELAY_CURR = REWDELAY(1) + rand(1)*(REWDELAY(2)-REWDELAY(1));
                tic;
                while toc*1000 <  REWDELAY_CURR
                    daspause(5);
                    [Hit Time] = DasCheck;
                    CheckKeys; %check key presses
                    CheckManual; %check status of the photo amp
                    ControlReward; % switch reward on or off;
                    ChangeFixPos;
                    ControlVisibility(Tar,[0 0]);
                end
                Par.EnterRewDelay = false;
                Par.AutoReward=true;
                
            end
            
            %% //////// INTERTRIAL AND CLEANUP ////////////////////////////
            SCNT = {'TRIALS'};
            SCNT(2) = { ['N: ' num2str(Par.Trlcount) ]}; % n trials
            SCNT(3) = { ['C: ' num2str(Par.Corrcount) ] }; % n correct
            SCNT(4) = { ['M: ' num2str(Par.Misscount + Par.Slowcount) ] }; % n missed
            SCNT(5) = { ['A: ' num2str(Par.Trlcount-Par.Corrcount-Par.Misscount-Par.Slowcount) ] }; % n aborted
            set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
            
            SD = dasgetnoise();
            SD = SD./Par.PixPerDeg;
            set(Hnd(2), 'String', SD );
            
            % ISI
            DrawBackground;
            lft=Screen('Flip', Par.window);
            
            Time = Lasttime;
            %fprintf('ITI\n');
            ISI_R2=ISI_R*rand(1);
            tic;
            while toc*1000 <  (ISI + ISI_R2 + ERR_ISI)
                %while Time < Lasttime + (ISI + ISI_R*rand(1))
                daspause(5);
                [Hit Time] = DasCheck;
                CheckKeys; %check key presses
                CheckManual; %check status of the photo amp
                ControlReward; % switch reward on or off;
                ChangeFixPos;
                ControlVisibility(Tar,[0 0]);
            end
            %fprintf(['ISI was ' num2str(toc) 's\n']);
            TrialEnded=true;
            
            % finish giving reward if necessary
            while Par.RewardRunning
                ControlReward;
            end
            
        end %WHILE_NOT_ESCAPED : END OF TRIAL LOOP %%%%%%%%%%%%%%%%%%%%%%%%
        
    end % multiple trials or stopped
    
    %% WrapUpRep
    % give some statistics on the screen when there are > 10 conditions
    if length(Stm.Cond)>=10
        fprintf(['THIS REPETITION ------\nSTARTED: ' num2str(TrialsStartedThisRep) ...
            '\nTARG: ' num2str(TrialsTargThisRep) ...
            '\nSLOW: ' num2str(TrialsSlowThisRep) ...
            '\nMISS: ' num2str(TrialsMissThisRep) ...
            '\nABORT: ' num2str(TrialsAbortThisRep) ...
            '\nREW(total): ' num2str(Log.TotalReward) '\n']);
    end
    % end eye recording if necessary
    if nR==Stm.nRepeatsStimSet && isempty(StimDynamic) && ...
            Par.EyeRecAutoTrigger && ~EyeRecMsgShown
        cn=0;
        while Par.EyeRecStatus == 0 || cn < 100
            pause(0.005)
            CheckEyeRecStatus; % checks the current status of eye-recording
            cn=cn+1;
        end
        if Par.EyeRecStatus % not recording
            SetEyeRecStatus(0);
            fprintf('\nStopped eye-recording. Save the file or add more runs.\n');
            fprintf(['Suggested filename: ' Par.MONKEY '_' DateString(1:end-2) '.tda\n']);
        else % not recording
            fprintf('\n>> Alert! Could not find a running eye-recording!\n');
        end
        EyeRecMsgShown=true;
    end
    fprintf('Repetition finished \n');
    
end % repeat conditions

%% Clean up and Save Log ==================================================
DrawBackground;
lft=Screen('Flip', Par.window);
dasjuice(0); %stop reward if its running

% go back to default priority
Priority(Par.oldPriority);

% save stuff
LogPath = fullfile(getenv('TRACKER_LOGS'),... % base log folder
    Par.SetUp,... % setup
    Par.LogFolder,... % task (/subtask)
    Par.MONKEY,... % subject
    [Par.MONKEY '_' DateString(1:8)],... % session
    [Par.MONKEY '_' DateString_sec]... % run
    );
[~,~,~] = mkdir(LogPath);
LogFn = [Par.SetUp '_' Par.MONKEY '_' DateString_sec];
[~,~,~] = mkdir(LogPath);
cd(LogPath)

%FileName=['Log_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString];
FileName=['Log_' LogFn];
warning off;

%mkdir('Log');cd('Log');
StimObj.Stm=Stm;
%mkdir([ Par.MONKEY '_' Par.STIMSETFILE '_' DateString]);
%cd([ Par.MONKEY '_' Par.STIMSETFILE '_' DateString]);

% runstim
fn=['Runstim_'  LogFn '.m'];
cfn=[mfilename('fullpath') '.m'];
copyfile(cfn,fn);
% parsettings
parsetpath = which(Par.PARSETFILE);
if isempty(ls(Par.PARSETFILE)) % doesn't exist yet
    copyfile(parsetpath,[Par.PARSETFILE '.m']);
end
% stimsettings
stimsetpath = which(Par.STIMSETFILE);
if isempty(ls(Par.STIMSETFILE)) % doesn't exist yet
    copyfile(stimsetpath,[Par.STIMSETFILE '.m']);
end

save(FileName,'Log','Par','StimObj');
cd(Par.ExpFolder)
warning on;

% print overview to cmd
fprintf(['\n\nTOTAL ============\nSTARTED: ' num2str(Par.Trlcount) ...
    '\nTARG: ' num2str(Par.Corrcount) ...
    '\nSLOW: ' num2str(Par.Slowcount) ...
    '\nMISS: ' num2str(Par.Misscount) ...
    '\nABORT: ' num2str(Par.Trlcount-...
    Par.Corrcount-Par.Misscount-Par.Slowcount) ...
    '\nREWARD: ' num2str(Log.TotalReward)]);

% end exp
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);
fprintf('\n\n------------------------------\n');
fprintf('Experiment ended as planned\n');
fprintf('------------------------------\n');

%% Standard functions called throughout the runstim =======================
% =========================================================================
% create fixation window around target
    function DefineEyeWin(Tar)
        FIX = 0;  %this is the fixation window
        TAR = [1 2]; %target window 1 & 2
        WIN = [Stm.Center(Par.PosNr,1), -Stm.Center(Par.PosNr,2), ...
            Stm.FixWinSizePix(1), Stm.FixWinSizePix(2), FIX];
        for tn=1:length(Tar)
            WIN2(tn,:)=[Tar(tn).PosPix(1), -Tar(tn).PosPix(2), ...
                Tar(tn).WinSizePix, Tar(tn).WinSizePix, TAR(tn)];
        end
        Par.WIN = [WIN;WIN2]';
    end
% draw fixation
    function DrawFix
        % fixation area
        rect=[...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm.FixDotSizePix/2];
        if ~Par.FixNeedsHandInBox || ...
                (Par.FixNeedsHandInBox && Par.BeamIsBlocked)
            Screen('FillOval',Par.window,Par.CurrFixCol,rect)
        end
    end
% draw background
    function DrawBackground
        Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
    end
% draw pre-target stimuli
    function DrawPreTargets(Tar)
        for tn=1:length(Tar)
            if strcmp(Tar(tn).Shape,'circle')
                Screen('FillOval',Par.window,Tar(tn).PreTargCol,Tar(tn).Rect);
            elseif strcmp(Tar(tn).Shape,'square')
                Screen('FillRect',Par.window,Tar(tn).PreTargCol,...
                    Tar(tn).Rect);
            elseif strcmp(Tar(tn).Shape,'diamond')
                Screen('FillPoly',Par.window,Tar(tn).PreTargCol,...
                    Tar(tn).Points,1);
            end
        end
    end
% draw target stimuli
    function DrawTargets(Tar,WhichTar)
        if isempty(WhichTar)
            WhichTar=1:length(Tar);
        end
        for tn=WhichTar
            if strcmp(Tar(tn).Shape,'circle')
                Screen('FillOval',Par.window,Tar(tn).Color,Tar(tn).Rect);
            elseif strcmp(Tar(tn).Shape,'square')
                Screen('FillRect',Par.window,Tar(tn).Color,...
                    Tar(tn).Rect);
            elseif strcmp(Tar(tn).Shape,'diamond')
                Screen('FillPoly',Par.window,Tar(tn).Color,...
                    Tar(tn).Points,1);
            end
        end
    end
% Draw reward delay indicators
    function DrawRewDelayIndicator(Tar,TarChosen)
        if strcmp(Tar(TarChosen).Shape,'circle')
            Screen('FrameOval',Par.window,Tar(TarChosen).Color,...
                Tar(TarChosen).Rect,Tar(TarChosen).RewDel_LW);
        elseif strcmp(Tar(TarChosen).Shape,'square')
            Screen('FrameRect',Par.window,Tar(TarChosen).Color,...
                Tar(TarChosen).Rect,Tar(TarChosen).RewDel_LW);
        elseif strcmp(Tar(Par.TarChosen).Shape,'diamond')
            Screen('FramePoly',Par.window,Tar(TarChosen).Color,...
                Tar(TarChosen).Points,Rect,Tar(TarChosen).RewDel_LW);
        end
    end
% control visibility of stimuli and fixation dot
    function ControlVisibility(Tar,FixStim) %#ok<INUSD>
        if Par.Pause
            Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
            Screen('Flip', Par.window);
            while Par.Pause
                CheckKeys
            end
            %         elseif Par.ToggleHideFix || Par.ToggleHideFix2 || ...
            %                 Par.ToggleHideStim || Par.ToggleHideStim2
            %             DrawBackground;
            %             if ~Par.ToggleHideFix && ~Par.ToggleHideFix2 && FixStim(1)
            %                 DrawFix;
            %             end
            %             if ~Par.ToggleHideStim && ~Par.ToggleHideStim2 && FixStim(2)
            %                 DrawTargets(Tar,[]);
            %             end
            %             Screen('Flip', Par.window);
        end
    end
% change stimulus features
    function ChangeFixPos
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
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type=['Pos' num2str(Par.PosNr)];
            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
            %DefineEyeWin(Tar);
            Par.SwitchPos=false;
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
                    case Par.KeyTriggerMR
                        Log.MRI.TriggerReceived = true;
                        Log.MRI.TriggerTime = ...
                            [Log.MRI.TriggerTime; Par.KeyTime];
                    case Par.KeyJuice
                        Par.ManualReward = true;
                        Log.ManualRewardTime = ...
                            [Log.ManualRewardTime; Par.KeyTime];
                    case Par.KeyStim
                        if ~Par.ToggleHideStim
                            Par.ToggleHideStim = true;
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='StimOff';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        else
                            Par.ToggleHideStim = false;
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='StimOn';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        end
                    case Par.KeyFix
                        if ~Par.ToggleHideFix
                            Par.ToggleHideFix = true;
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='FixOff';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        else
                            Par.ToggleHideFix = false;
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='FixOn';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        end
                    case Par.KeyPause
                        if ~Par.Pause
                            Par.Pause=true;
                            fprintf('Time-out ON\n');
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='PauseOn';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                            Par.PauseStartTime=Par.KeyTime;
                        else
                            Par.Pause=false;
                            Par.PauseStopTime=Par.KeyTime-Par.PauseStartTime;
                            fprintf(['Time-out OFF (' num2str(Par.PauseStopTime) ' s)\n']);
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='PauseOff';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        end
                    case Par.KeyRewTimeSet
                        Par.RewardTime=Par.RewardTimeSet;
                        Par.Times.Targ = Par.RewardFixHoldTime;
                        fprintf('Reward schedule set as defined in ParSettings\n');
                    case Par.KeyShowRewTime
                        fprintf('Reward amount (s):\n');
                        Par.RewardTime
                        fprintf('Fix time to get reward:\n' );
                        Par.Times.Targ
                    case Par.KeyCyclePos
                        if ~Par.PositionLocked
                            if Par.ToggleCyclePos
                                Par.ToggleCyclePos = false;
                                fprintf('Toggle automatic position cycling: OFF\n');
                            else
                                Par.ToggleCyclePos = true;
                                fprintf('Toggle automatic position cycling: ON\n');
                            end
                        end
                    case Par.KeyLockPos
                        if ~Par.PositionLocked
                            Par.PositionLocked=true;
                            fprintf('Fix position LOCKED\n');
                        else
                            Par.PositionLocked=false;
                            fprintf('Fix position UNLOCKED\n');
                        end
                    case Par.Key1
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = '1';
                        end
                    case Par.Key2
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = '2';
                        end
                    case Par.Key3
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = '3';
                        end
                    case Par.Key4
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = '4';
                        end
                    case Par.Key5
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = '5';
                        end
                    case Par.KeyNext
                        if ~Par.PositionLocked
                            Par.SwitchPos = true;
                            Par.WhichPos = 'Next';
                            % case Par.KeyPrevious
                            % Par.SwitchPos = true;
                            % Par.WhichPos = 'Prev';
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
    end
% check DAS for manual responses
    function CheckManual
        %check the incoming signal on DAS channel #4
        % NB dasgetlevel only starts counting at the third channel (#2)
        ChanLevels=dasgetlevel;
        %ChanLevels=zeros(1,4);
        Log.RespSignal = ChanLevels(4-2);
        % dasgetlevel starts reporting at channel 3, so subtract 2 from the channel you want (1 based)
        
        % it's a slightly noisy signal
        % on 32 bit windows
        % 3770-3800 means uninterrupted light beam
        % 2080-2090 means interrupted light beam
        % to be safe: take the cut-off halfway @2750
        % values are different for 64 bit windows
        %         if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 % 64bit das card
        %             Par.BeamIsBlocked = false;
        %             if Par.HandIsIn
        %                 Log.nEvents=Log.nEvents+1;
        %                 Log.Events(Log.nEvents).type='HandOut';
        %                 Log.Events(Log.nEvents).t=lft-Par.ExpStart;
        %                 Par.HandIsIn=false;
        %             end
        %         elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card
        %             Par.BeamIsBlocked = false;
        %             if Par.HandIsIn
        %                 Log.nEvents=Log.nEvents+1;
        %                 Log.Events(Log.nEvents).type='HandOut';
        %                 Log.Events(Log.nEvents).t=lft-Par.ExpStart;
        %                 Par.HandIsIn=false;
        %             end
        %         else
        %             Par.BeamIsBlocked = true;
        %             if ~Par.HandIsIn
        %                 Log.nEvents=Log.nEvents+1;
        %                 Log.Events(Log.nEvents).type='HandIn';
        %                 Log.Events(Log.nEvents).t=lft-Par.ExpStart;
        %                 Par.HandIsIn=true;
        %             end
        %         end
        
        if Log.RespSignal > 40000 % 64bit das card
            Par.BeamIsBlocked = false;
            if Par.HandIsIn
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='HandOut';
                Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                Par.HandIsIn=false;
            end
        else
            Par.BeamIsBlocked = true;
            if ~Par.HandIsIn
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='HandIn';
                Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                Par.HandIsIn=true;
            end
        end
        %
        %
        %         % interpret
        %         if Par.StimNeedsHandInBox && ~Par.BeamIsBlocked
        %             Par.ToggleHideStim2 = true;
        %         elseif Par.StimNeedsHandInBox && Par.BeamIsBlocked
        %             Par.ToggleHideStim2 = false;
        %         elseif ~Par.StimNeedsHandInBox
        %             Par.ToggleHideStim2 = false;
        %         end
        %
        %         if Par.FixNeedsHandInBox  && ~Par.BeamIsBlocked
        %             Par.ToggleHideFix2 = true;
        %         elseif Par.StimNeedsHandInBox && Par.BeamIsBlocked
        %             Par.ToggleHideFix2 = false;
        %         elseif ~Par.StimNeedsHandInBox
        %             Par.ToggleHideFix2 = false;
        %         end
        
    end
% reward control (check start/stop)
    function ControlReward
        if ~Par.RewardRunning
            if Par.ManualReward
                Par.RewardRunning=true;
                Par.RewardStartTime=GetSecs;
                Par.ManualReward=false;
                GiveRewardManual;
            elseif Par.AutoReward
                Par.RewardRunning=true;
                Par.RewardStartTime=GetSecs;
                Par.AutoReward=false;
                GiveRewardAuto;
            end
        else %reward is running
            if GetSecs >= Par.RewardStartTime+Par.RewardTimeCurrent
                daspause(5);
                dasjuice(0);
                Par.RewardRunning=false;
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
                Par.RewardTimeCurrent = Par.RewardTimeTarg;
        end
        
        % Give the reward
        if strcmp(computer,'PCWIN64')
            daspause(5);
            dasjuice(10); % 64bit das card
        else
            daspause(5);
            dasjuice(5) %old card dasjuice(5)
        end
        
        % Play back a sound
        if Par.RewardSound
            RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
            RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
            sound(RewY,Par.RewSndPar(1));
        end
        
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type='Reward';
        Log.Events(Log.nEvents).t=Par.RewardStartTime-Par.ExpStart;
    end
% give manual reward
    function GiveRewardManual
        Par.RewardTimeCurrent = Par.RewardTimeManual;
        % Give the reward
        if strcmp(computer,'PCWIN64')
            daspause(5);
            dasjuice(10); % 64bit das card
        else
            daspause(5);
            dasjuice(5) %old card dasjuice(5)
        end
        
        % Play back a sound
        if Par.RewardSound
            RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
            RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
            sound(RewY,Par.RewSndPar(1));
        end
        
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type='RewardMan';
        Log.Events(Log.nEvents).t=Par.RewardStartTime-Par.ExpStart;
    end
% check eye-tracker recording status
    function CheckEyeRecStatus
        ChanLevels=dasgetlevel;
        Par.CheckRecLevel=ChanLevels(6-2);
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
        dasbit(0,Par.EyeRecTriggerLevel);
        Log.nEvents=Log.nEvents+1;
        if Par.EyeRecTriggerLevel
            Log.Events(Log.nEvents).type='EyeRecOff';
        else
            Log.Events(Log.nEvents).type='EyeRecOn';
        end
        Log.Events(Log.nEvents).t=tEyeRecSet-Par.ExpStart;
    end
end