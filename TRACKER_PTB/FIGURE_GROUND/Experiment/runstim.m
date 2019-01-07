function runstim(Hnd)
% Updated January 2019, Chris Klink (c.klink@nin.knaw.nl)
% Figure-ground stimuli with fixation or lever task
global Par      %global parameters
global StimObj  %stimulus objects
global Log      %Logs

%% THIS SWITCH ALLOW TESTING THE RUNSTIM WITHOUT DASCARD & TRACKER ========
TestRunstimWithoutDAS = false;
%==========================================================================
% Do this only for testing without DAS
if TestRunstimWithoutDAS
    cd .. %#ok<*UNRCH>
    addpath(genpath(cd));
    ptbInit % initialize PTB
    Par.scr=Screen('screens');
    Par.ScrNr=max(Par.scr); % use the screen with the highest #
    Par.ScreenChoice = 'Mock';
    if Par.ScrNr==0
        % part of the screen
        [Par.window, Par.wrect] = ...
            Screen('OpenWindow',Par.ScrNr,0,[0 0 1000 800],[],2);
    else
        [Par.window, Par.wrect] = Screen('OpenWindow',Par.ScrNr,0,[],[],2);
    end
    [center(1), center(2)] = RectCenter(Par.wrect);
    
    % Reduce PTB3 verbosity
    oldLevel = Screen('Preference', 'Verbosity', 0); %#ok<*NASGU>
    Screen('Preference', 'VisualDebuglevel', 0);
    Screen('Preference','SkipSyncTests',1);
    
    %Do some basic initializing
    AssertOpenGL;
    KbName('UnifyKeyNames');
    
    %Set ParFile and Stimfile
    Par.PARSETFILE = 'ParSettings_NoDas';
    Par.STIMSETFILE = 'StimSettings';
    Par.MONKEY = 'TestWithoutDAS';
end
clc;

%% Prior To Dealing With Stimuli ==========================================
% set PTB priority to max
priorityLevel=MaxPriority(Par.window);
oldPriority=Priority(priorityLevel);
Par.ExpFolder = pwd;

%% set up the manual response task ========================================
for define_square=1 % left / square
    lmost=-1/2; rmost= 1/2;
    tmost=-1/2; bmost= 1/2;
    left_square = [lmost,tmost; rmost,tmost; rmost,bmost; lmost,bmost ];
end
for define_diamond=1 % right / diamond
    lmost=-sqrt(2)*1/2; rmost= sqrt(2)*1/2;
    tmost=-sqrt(2)*1/2; bmost= sqrt(2)*1/2;
    right_diamond = [lmost,0; 0,tmost; rmost,0; 0,bmost ];
end
for define_circle=1 % shown when subject needs to release response
    lmost=-sqrt(1/pi); rmost= sqrt(1/pi);
    tmost=-sqrt(1/pi); bmost= sqrt(1/pi);
    blocked_circle = [lmost, tmost, rmost, bmost ];
end

%% initialize stuff =======================================================
Par.ESC = false; %escape has not been pressed
GrandTotalReward=0;
LastRewardAdded=false;
CollectPerformance=[];
json_done=false;

Par.RewardStartTime=0;

% re-run parameter-file to update stim-settings without restarting Tracker
eval(Par.PARSETFILE); % can be chosen in menu
if ~isfield(Par,'PostErrorDelay')
    Par.PostErrorDelay = 0;
    fprintf('No PostErrorDelay defined: Setting it to 0\n');
end
if ~isfield(Par,'DelayOnMiss')
    Par.DelayOnMiss = 0;
    fprintf('No DelayOnMiss defined: Setting it to 0\n');
end
if ~isfield(Par,'RewardForHandsIn_Delay')
    Par.RewardForHandsIn_Delay = 0;
    fprintf('No RewardForHandsIn_Delay defined: Setting it to 0\n');
end
if ~isfield(Par,'RewardForHandIn_ResetIntervalWhenOut')
    Par.RewardForHandIn_ResetIntervalWhenOut = false;
    Par.RewardForHandIn_MinIntervalBetween = 0;
    fprintf('No RewardForHandIn_ResetIntervalWhenOut defined: Setting it to false\n');
end
if ~isfield(Par,'LeversUpTimeOut')
    Par.LeversUpTimeOut = [Inf 0];
    fprintf('No LeversUpTimeOut defined: Setting it to [Inf 0]\n');
end

% Add keys to fix left/right/random responses
Par.KeyLeftResp = KbName(',<');
Par.KeyRightResp = KbName('.>');
Par.KeyRandResp = KbName('/?');
Par.RespProbSetting=0; % initialize with random left/right indicators

Par.ScrCenter=Par.wrect(3:4)/2;
DateString = datestr(clock,30);
DateString = DateString(1:end-2);
Par_BU=Par;
if ~TestRunstimWithoutDAS
    refreshtracker(1);
end

if strcmp(Par.SetUp,'NIN')
    blockstr = inputdlg('BlockNr','BlockNr',1,{'000'});
    blockstr=blockstr{1};
end

% output stimsettings filename to cmd
fprintf(['Setup selected: ' Par.SetUp '\n']);
%fprintf(['Screen selected: ' Par.ScreenChoice '\n']);
fprintf(['TR: ' num2str(Par.TR) 's\n\n']);

fprintf(['=== Running ' Par.STIMSETFILE ' for ' Par.MONKEY ' ===\n']);
if ~strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
    % do no show this if reward is based on task
    if numel(Par.Times.Targ)>1
        fprintf(['Progressive fix-to-reward times between ' ...
            num2str(Par.Times.Targ(1,2)) ...
            ' and ' num2str(Par.Times.Targ(end,2)) ' ms\n']);
    else
        fprintf(['Hold fixation for ' num2str(Par.Times.Targ) ...
            ' ms to get reward\n']);
    end
end
Par.RewardTime=Par.RewardTimeSet;
Stm = StimObj.Stm;
fprintf(['Started at ' DateString '\n']);

% overwrite the stimsettings fix-window with the one from parsettings
Stm.FixWinSize = Par.FixWinSize;
if ~TestRunstimWithoutDAS
    refreshtracker(1);
end

% If multiple stimuli are defined, arrange order
Log.StimOrder=[];
for nR=1:Stm.nRepeatsStimSet
    if length(Stm.FigGnd)>1
        nSTIM=length(Stm.FigGnd);
        if Stm.RandomizeStim
            Log.StimOrder = [Log.StimOrder randperm(nSTIM)];
        else
            Log.StimOrder = [Log.StimOrder 1:nSTIM];
        end
    else
        Log.StimOrder = [Log.StimOrder 1];
    end
end

% This control parameter needs to be outside the stimulus loop
FirstEyeRecSet=false;
if ~TestRunstimWithoutDAS
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

%% Load stimuli before entering the display loop to be faster later =======
% Load stimuli
if Stm.LoadFromFile
    fprintf(['\nLoading figure-ground stimulus: ' Stm.FileName '...\n']);
    cd Stimuli; cd FigGnd
    D=load(Stm.FileName);
    stimulus=D.stimulus;
    cd ..; cd ..;
else
    fprintf('Creating figure-ground stimulus...\n');
    [stimulus, offscr] = ck_figgnd(Stm);
end

% Save stimuli
if Stm.SaveToFile
    fprintf(['\nSaving figure-ground stimulus: ' Stm.FileName '...\n']);
    cd Stimuli; cd RetMap;
    save(Stm.FileName,'stimulus','offscr','Stm','-v7.3');
    cd ..; cd ..;
end

% Create textures
switch Stm.StimType{2}
    case 'lines'
        for g = 1:length(Stm.Gnd)
            for gs=1:Stm.Gnd(g).NumSeeds
                Gnd(g).tex{gs,1} = Screen('MakeTexture',w,...
                    stimulus.Gnd(g).array{gs,1}); %#ok<*AGROW>
                if InvertPolarity
                    Gnd(g).tex{gs,2} = Screen('MakeTexture',w,...
                        stimulus.Gnd(g).array{gs,2});
                end
            end
        end
        for fs=1:Stm.Gnd(1).NumSeeds
            for p = 1:size(stimulus.Fig(f).textfig,2)
                % make figure texture
                Fig(f).tex{fs,p} = Screen('MakeTexture',w,...
                    stimulus.Fig(f).textfig{fs,p}); %#ok<*STRNU>
            end
        end
    case 'dots'
        for g = 1:length(Gnd) %#ok<*NODEF>
            for gs=1:Gnd(g).NumSeeds
                if MoveStim.nFrames > 0
                    for ms = 1:MoveStim.nFrames+1
                        % make texture
                        Gnd(g).tex{gs,ms,1} = Screen('MakeTexture',w,...
                            Gnd(g).array{gs,ms,1});
                        if InvertPolarity
                            Screen('FillRect',offscr.w,...
                                Gnd(g).dots.color*white)
                            Screen('DrawDots', offscr.w, XY,...
                                Gnd(g).dots.size,...
                                Gnd(g).backcol*white,...
                                offscr.center,Gnd(g).dots.type);
                            Gnd(g).array{gs,ms,2} = ...
                                Screen('GetImage',offscr.w);
                            % make texture
                            Gnd(g).tex{gs,ms,2} = ...
                                Screen('MakeTexture',w,...
                                Gnd(g).array{gs,ms,2});
                        end
                    end
                else
                    Gnd(g).tex{gs,1,1} = Screen('MakeTexture',w,...
                        Gnd(g).array{gs,1,1});
                    if InvertPolarity
                        Screen('FillRect',offscr.w,Gnd(g).dots.color*white)
                        Screen('DrawDots', offscr.w, XY,...
                            Gnd(g).dots.size,...
                            Gnd(g).backcol*white, offscr.center,...
                            Gnd(g).dots.type);
                        Gnd(g).array{gs,1,2} = Screen('GetImage',offscr.w);
                        % make texture
                        Gnd(g).tex{gs,1,2} = ...
                            Screen('MakeTexture',w,Gnd(g).array{gs,1,2});
                    end
                end
            end
        end
end

if Stm.nRepeatsStimSet == 0
    fprintf('No stop-moment defined. Keeps running till stopped');
    fprintf('Do not do this for scanning sessions!!');
    NumVolNeeded = inf;
    TotTime = inf;
else
    NumVolNeeded = Stm.nRepeatsStimSet*...
        (length(stm.FigGnd)*(Stm.stim_rep*...
        (Stm.stim_TRs+Stm.int_TRs)+Stm.int_TRs))+...
        Stm.PreDur_TRs+Stm.PostDur_TRs;
    TotTime = VolNeeded* Par.TR;
    
    if strcmp(Par.SetUp,'NIN') % ephys
        fprintf(['This StimSettings file will take ' ...
            num2str(TotTime) ' seconds.\n']);
        Log.uniqueID = round(rand(1).*2^14);
        send_serial_data(Log.uniqueID); % Xing's Blackrock rig
        % dasword(Log.uniqueID); % other ephys
        pause(.05); % make sure the word is received
        dasclearword();
        WordsSent=1;
        % keep track of how many words are sent so we can
        % back-check TDT against the log
        Log.Words(WordsSent)=Log.uniqueID;
        % collect all the words that are sent to TDT
    else
        fprintf(['This StimSettings file requires at least ' ...
            num2str(ceil(NumVolNeeded)) ...
            ' scanvolumes (check scanner)\n']);
    end
end

%% Run the experiment =====================================================
Par.ESC=false; Log.TotalTimeOut = 0; Par.Pause = false;
update_trackerfix_now = true;

%% INIT -------------------------------------------------------------------
nCyclesDone=0; nCyclesReported=0;
Log.TimeOutThisRun=0;

% Stimulus preparation -------------------------------------------
% Fixation
Stm.FixWinSizePix = round(Stm.FixWinSize*Par.PixPerDeg);
RunParStim_Saved = false;

Stm.FixDotSizePix = round(Stm.FixDotSize*Par.PixPerDeg);
Par.RespIndSizePix = round(Par.RespIndSize*Par.PixPerDeg);
Stm.FixDotSurrSizePix = round(Stm.FixDotSurrSize*Par.PixPerDeg);
Par.GoBarSizePix = round(Par.GoBarSize*Par.PixPerDeg);
Stm.Center =[];
for i=1:size(Stm.Position,2)
    Stm.Center =[Stm.Center; ...
        round(Stm.Position{i}.*Par.PixPerDeg)];
end

% Code Control Preparation ---------------------------------------
Par.FixStatToCMD=true;

% Some intitialization of control parameters
Log.MRI.TriggerReceived = false;
Log.MRI.TriggerTime = [];
Log.TotalReward=0;

% Initial fixation position
Par.PosNr=1; Par.PrevPosNr=1;

% Initialize the side of response
Par.ResponseSide=0;
Par.CurrResponseSide=Par.ResponseSide;
Par.CurrOrient=1; % 1=default, 2=switched
Par.Orientation = [1 0]; % [def a1lt] 0=hor, 1=vert
Par.ResponseState = Par.RESP_STATE_DONE;
Par.ResponseStateChangeTime = 0;

% Initialize KeyLogging
Par.KeyIsDown=false;
Par.KeyWasDown=false;
Par.KeyDetectedInTrackerWindow=false;

% Initialize control parameters
Par.SwitchPos = false;
Par.ToggleCyclePos = false; % overrules the Stim(1)setting; toggles with 'p'
Par.ToggleHideStim = false;
Par.ToggleHideFix = false;
Par.ManualReward = false;
Log.ManualRewardTime = [];
Par.PosReset=false;
Par.RewardStarted=false;
Par.MovieStopped=false;

% Trial Logging
Par.Response = 0; % maintained fixations
Par.ResponsePos = 0; % maintained fixations
Par.RespTimes = [];
Par.ManRewThisTrial=[];

Par.FirstInitDone=false;
Par.CheckFixIn=false;
Par.CheckFixOut=false;
Par.CheckTarget=false;
Par.RewardRunning=false;

% Initialize photosensor manual response
Par.BeamIsBlocked=false(size(Par.ConnectBox.PhotoAmp));
Par.HandIsIn =[false false];
Par.HandWasIn = Par.HandIsIn;
Par.LeverIsUp = [false; false];
Par.LeverWasUp = Par.LeverIsUp;
Par.BothLeversUp_time = Inf;
AutoPauseStartTime = Inf;
AutoPausing = false;

if ~Par.Pause
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
else
    Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite); % black first
end
lft=Screen('Flip', Par.window);

Par.ExpStart = lft;
Log.nEvents=1;
Log.Events = [];
Log.Events(Log.nEvents).type='ExpStart';
Log.Events(Log.nEvents).t=0;

Log.Eye =[];
Par.CurrEyePos = [];
Par.CurrEyeZoom = [];

EyeRecMsgShown=false;
RunEnded=false;

%% Eye-tracker recording --------------------------------------------------
if Par.EyeRecAutoTrigger
    if ~FirstEyeRecSet
        SetEyeRecStatus(0); % send record off signal
        hmb=msgbox('Prepare the eye-tracker for recording','Eye-tracking');
        uiwait(hmb);
        FirstEyeRecSet=true;
        pause(1);
    end
    
    MoveOn=false; StartSignalSent=false;
    while ~MoveOn
        StartEyeRecCheck = GetSecs;
        while ~Par.EyeRecStatus && GetSecs < StartEyeRecCheck + 3 % check for 3 seconds
            CheckEyeRecStatus; % checks the current status of eye-recording
            if ~StartSignalSent
                SetEyeRecStatus(1); StartSignalSent=true;
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
else
    fprintf('Eye recording not triggered (ephys or training?).\n')
    fprintf('Make sure it''s running!\n');
end

%% MRI triggered start ----------------------------------------------------
Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
lft=Screen('Flip', Par.window);
if Par.MRITriggeredStart
    fprintf('Waiting for MRI trigger (or press ''t'' on keyboard)\n');
    while ~Log.MRI.TriggerReceived
        CheckKeys;
        %Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        %lft=Screen('Flip', Par.window);
    end
    if Par.MRITrigger_OnlyOnce && lft-Par.ExpStart == 0
        fprintf('Triggering only once, move on automatically now.\n');
    else
        fprintf(['MRI trigger received after ' num2str(GetSecs-Par.ExpStart) ' s\n']);
    end
end

ExpStatus = 'PreDur'; PreLogDone = false;
srcrect = round([Par.wrect(1)+offscr.center(1)/2 ...
    Par.wrect(2)+offscr.center(2)/2 ...
    Par.wrect(3)+offscr.center(1)/2 ...
    Par.wrect(4)+offscr.center(2)/2]);

%% Stimulus loop ==========================================================
while ~Par.ESC
    %% First INIT ---------------------------------------------------------
    while ~Par.FirstInitDone
        %set control window positions and dimensions
        if ~TestRunstimWithoutDAS
            DefineEyeWin;
            refreshtracker(1) %for your control display
            last_tracker_update = GetSecs;
            SetWindowDas      %for the dascard, initializes eye control windows
        end
        
        % send trial nr to ephys rig
        if strcmp(Par.SetUp,'NIN') % ephys
            %dasword(Par.Trlcount(1)); % TDT
            send_serial_data(0); % Blackrock
            WordsSent+1; %#ok<*VUNUS>
            Log.Words(WordsSent)=0;
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='TrialStart';
            Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = 0;
        end
        
        Par.ResponseGiven=false;
        Par.FalseResponseGiven=false;
        Par.RespValid = false;
        Par.CorrectThisTrial=false;
        Par.LastFixInTime=0;
        Par.LastFixOutTime=0;
        Par.FixIn=false; %initially set to 'not fixating'
        Par.CurrFixCol=Stm.FixDotCol(1,:).*Par.ScrWhite;
        Par.FixInOutTime=[0 0];
        Par.FirstStimDrawDone=false;
        Par.ForceRespSide = false;
        Par.IsCatchBlock = false;
        Par.RewHandStart = GetSecs;
        Par.HandInNew_Moment = 0;
        Par.HandInPrev_Moment = 0;
        Par.Pause=false;
        
        nf=0;
        
        if TestRunstimWithoutDAS; Hit=0; end
        
        CurrPostErrorDelay = 0;
        nNonCatchTrials = 0;
        LastMissed = false;
        NumberOfConsecutiveErrors=0;
        if Par.CatchBlock.StartWithCatch
            Prev_nNonCatchTrials = -1;
        else
            Prev_nNonCatchTrials = nNonCatchTrials;
        end
        
        Log.dtm=[];
        
        if strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            RESP_NONE = 0;
            RESP_CORRECT = 1;
            RESP_FALSE = 2;
            RESP_MISS = 3;
            RESP_EARLY = 4;
            RESP_BREAK_FIX = 5;
            RespText = {'Correct', 'False', 'Miss', 'Early', 'Fix. break'};
            Par.ManResponse = [0 0 0 0 0];
        end
        RewardGivenForHandPos=false;
        Par.FirstInitDone=true;
    end
    
    FixTimeThisFlip = 0; NonFixTimeThisFlip = 0;
    Par.LastFlipFix = Par.FixIn;
    
    %% Check if eye enters fixation window --------------------------------
    if ~Par.FixIn %not fixating
        if ~Par.CheckFixIn && ~TestRunstimWithoutDAS
            dasreset(0); % start testing for eyes moving into fix window
            % sets timer to 0
            %fprintf('dasreset in\n')
        end
        Par.CheckFixIn=true;
        Par.CheckFixOut=false;
        Par.CheckTarget=false;
    elseif Par.FixIn %fixating
        if ~Par.CheckFixOut && ~TestRunstimWithoutDAS
            dasreset(1); % start testing for eyes leaving fix window
            % sets timer to 0
            %fprintf('dasreset out\n')
        end
        Par.CheckFixIn=false;
        Par.CheckFixOut=true;
        Par.CheckTarget=false;
    end
    
    %% Check eye position -------------------------------------------------
    %Hit=0;
    if ~TestRunstimWithoutDAS
        dasrun(5); % takes max 5 ms
        [Hit, Time] = DasCheck;
        %Hit = LPStat(1);   %Hit yes or no
        %Time = LPStat(0);  %time
    end
    
    %% interpret ----------------------------------------------------------
    if Par.CheckFixIn && Hit~=0
        % add time to fixation duration
        NonFixTimeThisFlip = NonFixTimeThisFlip+Time;
        Par.FixIn=true;
        %fprintf('fix in detected\n')
        Par.LastFixInTime=GetSecs;
        %Par.GoBarOnset = rand(1)*Par.EventPeriods(2)/1000 + ...
        %    Par.EventPeriods(1)/1000;
    elseif Par.CheckFixOut && Hit~=0
        % add time to non-fixation duration
        FixTimeThisFlip = FixTimeThisFlip+Time;
        Par.FixIn=false;
        %fprintf('fix out detected\n')
        Par.LastFixOutTime=GetSecs;
    end
      
    %% what happens depends on the status of the experiment ---------------
    switch ExpStatus
        case 'PreDur'
            if ~PreLogDone
                fprintf('>> Starting PreDur period <<\n')
                Log.StartPre=GetSecs;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='PreDurStart';
                Log.Events(Log.nEvents).t=Log.StartPre-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
                
                Pol_T0 = Log.StartPre;
                CurrPol = 1;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type=['CurrPol_' num2str(CurrPol)];
                Log.Events(Log.nEvents).t=Log.StartPre-Par.ExpStart;
                
                Seed_T0 = Log.StartPre;
                GndTexNum=Ranint(Stm.Gnd(1).NumSeeds);
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type=['Seed_' num2str(GndTexNum)];
                Log.Events(Log.nEvents).t=Log.StartPre-Par.ExpStart;
                
                PreLogDone=true;
                ms = 1; % for movement control
            end
        case 'StimBlock'
            switch WithinBlockStatus
                case 'FirstInt'
                    if ~FirstIntLogDone
                        fprintf('>> Starting Stimulus Block <<\n')
                        Log.StartInt=lft;
                        Log.nEvents=Log.nEvents+1;
                        Log.Events(Log.nEvents).type='Int';
                        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                        Log.Events(Log.nEvents).StimName = [];
                        
                        Pol_T0 = lft;
                        CurrPol = 1;
                        Log.nEvents=Log.nEvents+1;
                        Log.Events(Log.nEvents).type=...
                            ['CurrPol_' num2str(CurrPol)];
                        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                        
                        Seed_T0 = lft;
                        GndTexNum=Ranint(Stm.Gnd(1).NumSeeds);
                        Log.nEvents=Log.nEvents+1;
                        Log.Events(Log.nEvents).type=...
                            ['Seed_' num2str(GndTexNum)];
                        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                        
                        FirstIntLogDone = true;
                        ms = 1;
                    end
                    
                case 'Stim'
                    switch StimType
                        case 'Figure'
                            if ~StimLogDone
                                fprintf(['Stimulus nr' num2str '\n'])
                                Log.StartStim=lft;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='Figure';
                                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = ...
                                    Log.StimOrder;
                                StimLogDone=true;
                                ms = 1;
                                Par.Trlcount = Par.Trlcount+1;
                            end
                            
                        case 'Ground'
                            if ~StimLogDone
                                Log.StartStim=lft;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='Ground';
                                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = ...
                                    Log.StimOrder;
                                StimLogDone=true;
                                ms = 1;
                                Par.Trlcount = Par.Trlcount+1;
                            end
                    end
                    
                case 'Int'
                    if ~IntLogDone
                        Log.StartInt=lft;
                        Log.nEvents=Log.nEvents+1;
                        Log.Events(Log.nEvents).type='Int';
                        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                        Log.Events(Log.nEvents).StimName = [];
                        IntLogDone=true;
                        ms = 1;
                    end
            end
        case 'PostDur'
            if ~PostDurLogDone
                fprintf('>> Starting PostDur period <<\n')
                Log.StartPostDur=lft;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='PostDur';
                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
                PostDurLogDone=true;
                ms = 1;
            end
    end
 
    %% Draw Stimulus ------------------------------------------------------
    DrawUniformBackground;
    if ~Par.ToggleHideStim && ~Par.HideStim_BasedOnHandIn(Par) && ~Par.Pause
        % Fig &| Gnd
        if strcmp(ExpStatus,'PreDur') || strcmp(ExpStatus,'PostDur')
            % gnd
            if strcmp(Stm.StimType{2},'lines')
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,CurrPol},...
                    srcrect,[],Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).orient,[],[],[],[],...
                    kPsychUseTextureMatrixForRotation);
            elseif strcmp(Stm.StimType{2},'dots')
                if Stm.MoveStim.Do && ...
                        lft>=Log.StartPre+Stm.MoveStim.SOA && ms<Stm.MoveStim.nFrames+1
                    ms=ms+1;
                end
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,ms,CurrPol},...
                    srcrect,[],Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).orient,[],[],[],[],...
                    kPsychUseTextureMatrixForRotation);
            end
            
        elseif strcmp(ExpStatus,'StimBlock') && ...
                (strcmp(WithinBlockStatus,'FirstInt') || ...
                strcmp(WithinBlockStatus,'Int'))
            if strcmp(Stm.StimType{2},'lines')
                % int gnd
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,CurrPol},...
                    srcrect,[],Stm.IntGnd.orient,[],[],[],[],...
                    kPsychUseTextureMatrixForRotation);
            elseif strcmp(Stm.StimType{2},'dots')
                if Stm.MoveStim.Do && ...
                        lft>=Log.StartInt+Stm.MoveStim.SOA && ms<Stm.MoveStim.nFrames+1
                    ms=ms+1;
                end
                % gnd
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,ms,CurrPol},...
                    srcrect,[],Stm.IntGnd.orient,[],[],[],[],...
                    kPsychUseTextureMatrixForRotation);
            end
        elseif strcmp(ExpStatus,'StimBlock') && ...
                strcmp(WithinBlockStatus,'Stim')
            
            if strcmp(Stm.StimType{2},'lines')
                % gnd
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,CurrPol},...
                    srcrect,[],Stm.Gnd(Stm.FigGnd{Log.StimOrder}(1)).orient,...
                    [],[],[],[],kPsychUseTextureMatrixForRotation);
                % fig
                Screen('DrawTexture',w, ...
                    Stm.Fig(Stm.FigGnd{Log.StimOrder}(1)).tex{GndTexNum,CurrPol},...
                    Fig(Stm.FigGnd{Log.StimOrder}(1)).RectSrc, ...
                    Fig(Stm.FigGnd{Log.StimOrder}(1)).RectDest);
            elseif strcmp(Stm.StimType{2},'dots')
                if Stm.MoveStim.Do && ...
                        lft>=Log.StartStim+Stm.MoveStim.SOA && ms<Stm.MoveStim.nFrames+1
                    ms=ms+1;
                end
                % gnd
                Screen('DrawTexture', w, ...
                    Stm.Gnd(Stm.FigGnd{Log.StimOrder}(2)).tex{GndTexNum,ms,CurrPol},...
                    srcrect,[],Stm.Gnd(Stm.FigGnd{Log.StimOrder}(1)).orient,...
                    [],[],[],[],kPsychUseTextureMatrixForRotation);
                % fig
                Screen('DrawTexture',w, ...
                    Stm.Fig(Stm.FigGnd{Log.StimOrder}(1)).tex{GndTexNum,ms,CurrPol},...
                    Fig(Stm.FigGnd{Log.StimOrder}(1)).RectSrc, ...
                    Fig(Stm.FigGnd{Log.StimOrder}(1)).RectDest);
            end
        end
    end
        
    %% Draw fixation dot --------------------------------------------------
    if ~Par.ToggleHideFix && ~Par.HideFix_BasedOnHandIn(Par) ...
            && ~Par.Pause
        DrawFix;
    end
    
    if ~FixTimeThisFlip && ~NonFixTimeThisFlip
        % new event
        if FixTimeThisFlip > NonFixTimeThisFlip % more fixation than not
            Par.AddFixIn = true;
        else
            Par.AddFixIn = false;
        end
    else
        % continuation of previous flip
        if Par.FixIn % already fixating
            Par.AddFixIn = true;
        else
            Par.AddFixIn = false;
        end
    end
    
    %% darken the screen if on time-out -----------------------------------
    if Par.Pause
        Screen('FillRect',Par.window,[0 0 0]);
    end
    
    %% Calculate proportion fixation for this flip-time and label it ------
    % fix or no-fix
    if Par.FixIn
        if Par.RewardFixFeedBack
            Par.CurrFixCol=Stm.FixDotCol(2,:).*Par.ScrWhite;
        end
        
        Par.Trlcount=Par.Trlcount+1;
        %refreshtracker(3);
        if GetSecs >= Par.LastFixInTime+Par.Times.TargCurrent/1000 % fixated long enough
            % start Reward
            if ~Par.RewardRunning && ~TestRunstimWithoutDAS && ~Par.Pause && ...
                    Par.Rew_BasedOnHandIn(Par) && ~Par.HideFix_BasedOnHandIn(Par)
                % nCons correct fixations
                Par.CorrStreakcount=Par.CorrStreakcount+1;
                Par.Response=Par.Response+1;
                Par.ResponsePos=Par.ResponsePos+1;
                % Start reward ========================================
                if ~strcmp(Par.ResponseBox.Task, 'DetectGoSignal') % when not doing task
                    GiveRewardAutoFix;  % ------------------------ Fix Reward
                    Par.RewardRunning=true;
                    Par.RewardStartTime=GetSecs;
                    Par.LastFixInTime=Par.RewardStartTime; % reset start fix time
                end
                Par.Trlcount=Par.Trlcount+1;
                %refreshtracker(1);refreshtracker(3);
            end
        end
    else
        Par.CurrFixCol=Stm.FixDotCol(1,:).*Par.ScrWhite;
        Par.CorrStreakcount=[0 0];
        %refreshtracker(1);
    end
    
    %% Stop reward --------------------------------------------------------
    StopRewardIfNeeded();
    
    %% Autopause due to lever lifts ---------------------------------------
    if Par.LeversUpTimeOut(2) % there is a timeout interval defined
        if all(Par.LeverIsUp) && ... % both up
                GetSecs > Par.BothLeversUp_time + Par.LeversUpTimeOut(1) && ...
                ~Par.Pause % levers have been up too long
            Par.Pause=true;
            fprintf(['Automatic time-out due to lever lifts ON (min ' ...
                num2str(Par.LeversUpTimeOut(2)) 's)\n']);
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='AutoPauseOn';
            Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = [];
            AutoPauseStartTime=GetSecs;
            AutoPausing = true;
        elseif GetSecs > AutoPauseStartTime + Par.LeversUpTimeOut(2) && ...
                Par.Pause && AutoPausing % Time-out time over
            if all(Par.LeverIsUp)
                % still both up, continue time-out
            else
                Par.Pause=false;
                fprintf('Automatic time-out due to lever lifts OFF\n');
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='AutoPauseOff';
                Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
                AutoPausing = false;
            end
        end
    end
    
    %% if doing Par.ResponseBox.Task of 'DetectGoSignal': -----------------
    if strcmp(Par.ResponseBox.Task, 'DetectGoSignal') && ~TestRunstimWithoutDAS
        % ==== Start wait period ====
        if Par.ResponseState == Par.RESP_STATE_DONE && ...
                Par.CanStartTrial(Par)
            UpdateHandTaskState(Par.RESP_STATE_WAIT);
            %Par.ResponseState = Par.RESP_STATE_WAIT;
            %Par.ResponseStateChangeTime = GetSecs;
            StartWaitTime = Par.ResponseStateChangeTime;
            if ~Par.IsCatchBlock
                if Par.ResponseSide == 0 || Par.ForceRespSide
                    if NumberOfConsecutiveErrors >= Par.MaxNumberOfConsecutiveErrors
                        if Par.ResponseSide == 1
                            Par.ResponseSide = 2;
                        else
                            Par.ResponseSide =1;
                        end
                    else
                        if Par.RespProbSetting % 0=random, 1=left, 2=right
                            Par.ResponseSide = Par.RespProbSetting;
                        else
                            Par.ResponseSide = randi([1 2]);
                            Par.ForceRespSide = false;
                        end
                    end
                end
            elseif Par.IsCatchBlock % catchblock
                Par.ResponseSide = CatchSides(1);
            end
            Par.CurrResponseSide = Par.ResponseSide;
            Log.Events(Log.nEvents).StimName = num2str(Par.ResponseSide);
            Par.GoBarOnset = rand(1)*Par.EventPeriods(2)/1000 + ...
                Par.EventPeriods(1)/1000 + CurrPostErrorDelay/1000;
            
            % Give side indicator (1 or 2) ... again
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type=strcat(...
                'HandTask-TargetSide', num2str(Par.ResponseSide));
            Log.Events(Log.nEvents).t=Par.ResponseStateChangeTime;
            % ==== During wait period ====
        elseif Par.ResponseState == Par.RESP_STATE_WAIT
            if Par.RespIndLeds; dasbit(Par.LED_B(1),0);dasbit(Par.LED_B(2),0);end % LEDS off
            if GetSecs >= Par.ResponseStateChangeTime + Par.GoBarOnset
                UpdateHandTaskState(Par.RESP_STATE_GO);
                %Par.ResponseState = Par.RESP_STATE_GO;
                %Par.ResponseStateChangeTime = GetSecs;
                CurrPostErrorDelay=0;
            end
            % check for early responses before go-signal -----
            t = GetSecs;
            if (Par.CorrectResponseGiven(Par) || ... % Early during wait
                    Par.IncorrectResponseGiven(Par))
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                if Par.CorrectResponseGiven(Par)
                    Log.Events(Log.nEvents).StimName = 'EarlyCorrect';
                else
                    Log.Events(Log.nEvents).StimName = 'EarlyIncorrect';
                end
                Par.ManResponse(RESP_EARLY) = Par.ManResponse(RESP_EARLY)+1;
                %fprintf('Early during wait\n');
                CurrPostErrorDelay = Par.PostErrorDelay;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnEarly % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                end
                if Par.IsCatchBlock
                    CatchSides = Shuffle(CatchSides);
                else
                    nNonCatchTrials = nNonCatchTrials+1;
                end
                LastMissed = false;
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(4) && ...
                        all(~isnan(Par.FeedbackSoundPar(4,:)))
                    if Par.FeedbackSoundPar(4)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(4).h, 1, 0, 1);
                        catch
                        end
                    end
                end
            end
            % -----
            % ==== Go signal is given ====
        elseif Par.ResponseState == Par.RESP_STATE_GO
            t = GetSecs;
            % ---- Early after go ----
            if (Par.CorrectResponseGiven(Par) || ...
                    Par.IncorrectResponseGiven(Par)) && ...
                    t < Par.ResponseStateChangeTime + ...
                    Par.ResponseAllowed(1)/1000
                % Early response after go-signal ------
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                if Par.CorrectResponseGiven(Par)
                    Log.Events(Log.nEvents).StimName = 'EarlyCorrect';
                else
                    Log.Events(Log.nEvents).StimName = 'EarlyIncorrect';
                end
                Par.ManResponse(RESP_EARLY) = Par.ManResponse(RESP_EARLY)+1;
                %fprintf('Early after go\n');
                CurrPostErrorDelay = Par.PostErrorDelay;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnEarly % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                    if Par.IsCatchBlock
                        CatchSides = Shuffle(CatchSides);
                    else
                        nNonCatchTrials = nNonCatchTrials+1;
                    end
                end
                LastMissed = false;
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(4) && ...
                        all(~isnan(Par.FeedbackSoundPar(4,:)))
                    if Par.FeedbackSoundPar(4)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(4).h, 1, 0, 1);
                        catch
                        end
                    end
                end
                % ---- Incorrect ----
            elseif Par.IncorrectResponseGiven(Par) && Par.RespLeverMatters
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                Log.Events(Log.nEvents).StimName = 'Incorrect';
                NumberOfConsecutiveErrors=NumberOfConsecutiveErrors+1;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnError % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                end
                % RESP_NONE =  0; RESP_CORRECT = 1;
                % RESP_FALSE = 2; RESP_MISS = 3;
                % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                Par.ManResponse(RESP_FALSE) = Par.ManResponse(RESP_FALSE)+1;
                %fprintf('Error\n');
                CurrPostErrorDelay = Par.PostErrorDelay;
                if Par.IsCatchBlock
                    CatchSides = Shuffle(CatchSides);
                else
                    nNonCatchTrials = nNonCatchTrials+1;
                end
                LastMissed = false;
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(2) && ...
                        all(~isnan(Par.FeedbackSoundPar(2,:)))
                    if Par.FeedbackSoundPar(2)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(2).h, 1, 0, 1);
                        catch
                        end
                    end
                end
                % ---- Correct ----
            elseif Par.CorrectResponseGiven(Par) && Par.RespLeverMatters
                %Par.ResponseStateChangeTime = GetSecs;
                %Par.ResponseState = Par.RESP_STATE_DONE;
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                Log.Events(Log.nEvents).StimName = 'Hit';
                NumberOfConsecutiveErrors=0;
                GiveRewardAutoTask;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnCorrect % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                end
                % RESP_NONE =  0; RESP_CORRECT = 1;
                % RESP_FALSE = 2; RESP_MISS = 3;
                % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                Par.ManResponse(RESP_CORRECT) = Par.ManResponse(RESP_CORRECT)+1;
                %fprintf('Correct\n');
                CurrPostErrorDelay = Par.PostCorrectDelay;
                if Par.IsCatchBlock
                    CatchSides(1) = [];
                else
                    nNonCatchTrials = nNonCatchTrials+1;
                end
                LastMissed = false;
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(1) && ...
                        all(~isnan(Par.FeedbackSoundPar(1,:)))
                    if Par.FeedbackSoundPar(1)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(1).h, 1, 0, 1);
                        catch
                        end
                    end
                end
                % Correct if side doesn't matter
            elseif ~Par.RespLeverMatters && ...
                    (Par.CorrectResponseGiven(Par) || Par.IncorrectResponseGiven(Par))
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                Log.Events(Log.nEvents).StimName = 'HitEither';
                GiveRewardAutoTask;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnCorrect % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                end
                % RESP_NONE =  0; RESP_CORRECT = 1;
                % RESP_FALSE = 2; RESP_MISS = 3;
                % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                Par.ManResponse(RESP_CORRECT) = Par.ManResponse(RESP_CORRECT)+1;
                %fprintf('Correct\n');
                CurrPostErrorDelay = Par.PostCorrectDelay;
                if Par.IsCatchBlock
                    CatchSides(1) = [];
                else
                    nNonCatchTrials = nNonCatchTrials+1;
                end
                LastMissed = false;
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(1) && ...
                        all(~isnan(Par.FeedbackSoundPar(1,:)))
                    if Par.FeedbackSoundPar(1)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(1).h, 1, 0, 1);
                        catch
                        end
                    end
                end
                % ---- Miss ----
            elseif t >=  Par.ResponseStateChangeTime + ...
                    Par.ResponseAllowed(2)/1000
                UpdateHandTaskState(Par.RESP_STATE_DONE);
                Log.Events(Log.nEvents).StimName = 'Miss';
                %Par.ResponseState = Par.RESP_STATE_DONE;
                %Par.ResponseStateChangeTime = GetSecs;
                if ~Par.ForceRespSide
                    if rand(1) <= Par.ProbSideRepeatOnMiss % same side
                        Par.ResponseSide=Par.ResponseSide; % keep same
                    else
                        if Par.ResponseSide==1
                            Par.ResponseSide=2;
                        else
                            Par.ResponseSide=1;
                        end
                    end
                end
                % RESP_NONE =  0; RESP_CORRECT = 1;
                % RESP_FALSE = 2; RESP_MISS = 3;
                % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                Par.ManResponse(RESP_MISS) = Par.ManResponse(RESP_MISS)+1;
                LastMissed = true;
                %fprintf('Miss\n');
                CurrPostErrorDelay = Par.DelayOnMiss;
                if Par.IsCatchBlock
                    CatchSides = Shuffle(CatchSides);
                else
                    nNonCatchTrials = nNonCatchTrials+1;
                end
                % play feedback sound
                if Par.ResponseState > 0 && ...
                        isfield(Par, 'FeedbackSound') && ...
                        isfield(Par, 'FeedbackSoundPar') && ...
                        Par.FeedbackSound(3) && ...
                        all(~isnan(Par.FeedbackSoundPar(3,:)))
                    if Par.FeedbackSoundPar(3)
                        try
                            % fprintf('trying to play a sound\n')
                            PsychPortAudio('Start', ...
                                Par.FeedbackSoundSnd(3).h, 1, 0, 1);
                        catch
                        end
                    end
                end
            end
        end
        % draw the indicators
        if ~Par.ToggleHideFix && ~Par.HideFix_BasedOnHandIn(Par) && ~Par.Pause
            if Par.ResponseState == Par.RESP_STATE_WAIT  && ... ~LastMissed && ...
                    (isfield(Par,'NoIndicatorDuringPunishDelay') && ...
                    Par.NoIndicatorDuringPunishDelay) && ...
                    (GetSecs < StartWaitTime + CurrPostErrorDelay/1000)
            else
                DrawHandIndicator;
                DrawGoBar;
            end
        end
    end
    
    %% dim the screen if requested due to hand position -------------------
    AutoDim; % checks by itself if it's required
    
    %% refresh the screen -------------------------------------------------
    %lft=Screen('Flip', Par.window, prevlft+0.9*Par.fliptimeSec);
    lft=Screen('Flip', Par.window); % as fast as possible
    nf=nf+1;
    
    %% log eye-info if required -------------------------------------------
    LogEyeInfo;
    
    %% Switch position if required to do this automatically ---------------
    if Par.ToggleCyclePos && Stm.CyclePosition && ...
            Par.Trlcount(1) >= Stm.CyclePosition
        % next position
        Par.SwitchPos = true;
        Par.WhichPos = 'Next';
        ChangeStimulus;
        Par.SwitchPos = false;
    end
    
    %% update fixation times ----------------------------------------------
    if nf>1 %&& ~Stm.IsPreDur
        dt=lft-prevlft;
        % log the screen flip timing
        Log.dtm=[Log.dtm;dt GetSecs-Par.ExpStart];
        if Par.FixIn % fixating
            Par.FixInOutTime(end,1)=Par.FixInOutTime(end,1)+dt;
        else
            Par.FixInOutTime(end,2)=Par.FixInOutTime(end,2)+dt;
        end
    end
    
    %% Update Tracker window ----------------------------------------------
    if ~TestRunstimWithoutDAS && update_trackerfix_now
        %SCNT = {'TRIALS'};
        SCNT(1) = { ['F: ' num2str(Par.Response) '  FC: ' num2str(Par.CorrStreakcount(2))]};
        %SCNT(2) = { ['FC: ' num2str(Par.CorrStreakcount(2)) ] };
        SCNT(2) = { ['%FixC: ' ...
            sprintf('%0.1f',100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:))))]};
        if size(Par.FixInOutTime,1)>=2
            SCNT(3) = { ['%FixR: ' ...
                sprintf('%0.1f',100* ( sum(Par.FixInOutTime(2:end,1))/sum( sum(Par.FixInOutTime(2:end,:)))))]};
        else
            SCNT(3) = { ['%FixR: ' ...
                sprintf('%0.1f',100* ( sum(Par.FixInOutTime(:,1))/sum( sum(Par.FixInOutTime) ) ))]};
        end
        if strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            SCNT(4) = { ['C: ' num2str(Par.ManResponse(RESP_CORRECT)) ...
                '  F: ' num2str(Par.ManResponse(RESP_FALSE))]};
            SCNT(5) = { ['M: ' num2str(Par.ManResponse(RESP_MISS)) ...
                '  E: ' num2str(Par.ManResponse(RESP_EARLY))]};
        else
            SCNT(4) = { 'NO MANUAL'};
            SCNT(5) = { 'NO MANUAL'};
        end
        SCNT(6) = { ['Rew: ' num2str(Log.TotalReward) ] };
        set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
        % Give noise-on-eye-channel info
        SD = dasgetnoise();
        SD = SD./Par.PixPerDeg;
        set(Hnd(2), 'String', SD )
        last_trackerfix_update = GetSecs;
    end
    if ~TestRunstimWithoutDAS && ...
            GetSecs - last_trackerfix_update >= 1 % update tracker every second
        update_trackerfix_now=true;
    else
        update_trackerfix_now=false;
    end
    
    %% Catch block --------------------------------------------------------
    if strcmp(Par.ResponseBox.Task,'DetectGoSignal') && ...
            Par.CatchBlock.do && ~Par.IsCatchBlock && ...
            nNonCatchTrials > Prev_nNonCatchTrials && ...
            mod(nNonCatchTrials,Par.CatchBlock.AfterNumberOfTrials)==0
        Par.IsCatchBlock = true;
        %fprintf('Catch block started...')
        CatchSides = Shuffle([ones(1,Par.CatchBlock.NoCorrectPerSideNeeded) ...
            2*ones(1,Par.CatchBlock.NoCorrectPerSideNeeded)]);
        Prev_nNonCatchTrials = nNonCatchTrials;
    elseif strcmp(Par.ResponseBox.Task,'DetectGoSignal') && ...
            Par.CatchBlock.do && Par.IsCatchBlock && isempty(CatchSides)
        Par.IsCatchBlock = false;
        %fprintf('completed\n')
    end
    
    %% Stop reward --------------------------------------------------------
    StopRewardIfNeeded();
    
    %% Check time, adjust status, and change stim -------------------------
    switch ExpStatus
        case 'PreDur'
            % check for refresh seed ---
            if Stm.Gnd(1).NumSeeds && Stm.RefreshSeed > 0 && ...
                    lft-Seed_T0 >= Stm.RefreshSeed
                GndTexNum=ChangeSeed(GndTexNum);
                Seed_T0=lft;
            end
            
            % check for refresh polarity ---
            if Stm.InvertPolarity && lft-Pol_T0 >= Stm.RefreshPol
                ChangePolarity(CurrPol);
                Pol_T0=lft;
            end
            
            % check for end of period ---
            if lft-Log.StartPre >= Stm.PreDur_TRs*Par.TR
                ExpStatus = 'StimBlock';
                WithinBlockStatus = 'FirstInt';
                FirstIntLogDone = false;
            end
        case 'StimBlock'
            switch WithinBlockStatus
                case 'FirstInt'
                    % check for refresh seed ---
                    if Stm.Gnd(1).NumSeeds && Stm.RefreshSeed > 0 && ...
                            lft-Seed_T0 >= Stm.RefreshSeed
                        GndTexNum=ChangeSeed(GndTexNum);
                        Seed_T0=lft;
                    end
                    
                    % check for refresh polarity ---
                    if Stm.InvertPolarity && lft-Pol_T0 >= Stm.RefreshPol
                        ChangePolarity(CurrPol);
                        Pol_T0=lft;
                    end
                    
                    % check for end of period ---
                    if lft-Log.StartInt >= Stm.int_TRs*Par.TR
                        WithinBlockStatus = 'Stim';
                        StimLogDone = false;
                        StimNr = 1;
                        StimRepNr = 1;
                        StimType = 'Figure'; % start with figure
                        NumGndMoves=0;
                    end
                    
                case 'Stim'
                    switch StimType
                        case 'Figure'
                            if lft-Log.StartStim >= Stm.stim_TRs*Par.TR
                                WithinBlockStatus = 'Int';
                                IntLogDone = false;
                            end
                        case 'Ground'
                            if lft-Log.StartStim >= Stm.stim_TRs*Par.TR
                                WithinBlockStatus = 'Int';
                                IntLogDone = false;
                            end
                    end
                    
                    if Stm.MoveGnd.Do && strcmp(Stm.StimType{2},'lines')
                        if lft >= Log.StartStim + Stm.MoveGnd.SOA && ...
                                NumGndMoves < Stm.MoveGnd.nFrames
                            srcrect = [srcrect(1) + Stm.MoveGnd.XY(1) ...
                                srcrect(2) + Stm.MoveGnd.XY(2) ...
                                srcrect(3) + Stm.MoveGnd.XY(1) ...
                                srcrect(4) + Stm.MoveGnd.XY(2) ];
                            NumGndMoves=NumGndMoves+1;
                        elseif lft < Log.StartStim + StmMoveGnd.SOA
                            srcrect = round([Par.wrect(1)+offscr.center(1)/2 ...
                                Par.wrect(2)+offscr.center(2)/2 ...
                                Par.wrect(3)+offscr.center(1)/2 ...
                                Par.wrect(4)+offscr.center(2)/2]);
                        else
                            % don't change srcrect anymore
                        end
                    else
                        srcrect = round([Par.wrect(1)+offscr.center(1)/2 ...
                            Par.wrect(2)+offscr.center(2)/2 ...
                            Par.wrect(3)+offscr.center(1)/2 ...
                            Par.wrect(4)+offscr.center(2)/2]);
                    end
                    
                case 'Int'
                    if lft-Log.StartInt >= Stm.int_TRs*Par.TR
                        if strcmp(WithinBlockStatus,'Figure')
                            WithinBlockStatus = 'Ground';
                            StimLogDone = false;
                        else
                            WithinBlockStatus = 'Figure';
                            StimLogDone = false;
                            if StimRepNr == Stm.stim_rep
                                StimRepNr = 1;
                            else
                                StimRepNr = StimRepNr+1;
                            end
                            if StimNr == length(Log.StimOrder)
                                % all stimuli done
                                ExpStatus = 'PostDur';
                                PostDurLogDone = false;
                            else
                                StimNr = StimNr+1;
                            end
                        end
                        
                    end
            end
        case 'PostDur'
            % check for refresh seed ---
            if Stm.Gnd(1).NumSeeds && Stm.RefreshSeed > 0 && ...
                    lft-Seed_T0 >= Stm.RefreshSeed
                GndTexNum=ChangeSeed(GndTexNum);
                Seed_T0=lft;
            end
            
            % check for refresh polarity ---
            if Stm.InvertPolarity && lft-Pol_T0 >= Stm.RefreshPol
                ChangePolarity(CurrPol);
                Pol_T0=lft;
            end
    end
    
    %% Do this routine for all remaining flip time ------------------------
    DoneOnce=false;
    while ~DoneOnce || GetSecs < prevlft+0.80*Par.fliptimeSec
        DoneOnce=true;
        
        %% check for key-presses --------------------------------------
        CheckKeys; % internal function
        
        %% Change stimulus if required --------------------------------
        ChangeStimulus;
        
        %% give manual reward -----------------------------------------
        if Par.ManualReward && ~TestRunstimWithoutDAS
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        %% give reward for hand in box --------------------------------
        if Par.RewardForHandsIn && any(Par.HandIsIn) && ~Par.Pause && ...
                ~Par.RewardRunning && ...
                GetSecs - Par.HandInNew_Moment > Par.RewardForHandsIn_Delay
            if GetSecs - Par.RewHandStart > Par.RewardForHandIn_MinInterval % kept in long enough
                GiveRewardAutoHandIn;
            elseif Par.RewardForHandIn_ResetIntervalWhenOut && ...
                    Par.HandInPrev_Moment ~= Par.HandInNew_Moment && ...
                    GetSecs - Par.RewHandStart > Par.RewardForHandIn_MinIntervalBetween
                GiveRewardAutoHandIn;
            end
        end
        
        %% check photosensor ------------------------------------------
        if ~TestRunstimWithoutDAS
            CheckManual;
            if ~strcmp(Par.ResponseBox.Task,'DetectGoSignal') && ...
                    Par.StimNeeds.HandIsIn && ...
                    ((strcmp(Par.HandInBothOrEither,'Both') && ~any(Par.HandIsIn)) || ...
                    (strcmp(Par.HandInBothOrEither,'Either') && ~all(Par.HandIsIn)))
                % assumes only 1 photo-channel in use, or only checks
                % first defined channel
                Par.FixIn = false;
                % reset the fixation status to false if his hands are not where
                % they should be, otherwise he may get an immediate reward when
                % he maintains the proper eye-position and puts his hand in
                %
                % Doing this via StimNeedsHandInBox allows showing a fix dot
                % which is only marked as fixating when the hands are also in
                % the box
            end
        end
        
        %% Stop reward ------------------------------------------------
        StopRewardIfNeeded();
    end
    
end

%% Clean up and Save Log --------------------------------------------------
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
        fprintf(['Suggested filename: ' Par.MONKEY '_' DateString '.tda\n']);
    else % not recording
        fprintf('\n>> Alert! Could not find a running eye-recording!\n');
    end
    EyeRecMsgShown=true;
end

if ~isempty(Stm.Descript) && ~TestRunstimWithoutDAS
    % Empty the screen
    if ~Par.Pause
        Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
    else
        Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite); % black first
    end
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    if ~TestRunstimWithoutDAS
        dasjuice(0); %stop reward if its running
    end
    
    % go back to default priority
    Priority(oldPriority);
    
    % save stuff
    LogPath = fullfile(Par.LogFolder,Par.SetUp,Par.MONKEY,...
        [Par.MONKEY '_' DateString(1:8)],[Par.MONKEY '_' DateString]);
    warning off;mkdir(LogPath);warning on;
    LogFn = [Par.SetUp '_' Par.MONKEY '_' DateString];
    cd(LogPath)
    
    if ~TestRunstimWithoutDAS
        if strcmp(Par.SetUp,'NIN')
            FileName=['Log_' LogFn '_' ...
                Stm.Descript '_Run' num2str(1) '_Block' num2str(blockstr)];
        else
            FileName=['Log_' LogFn '_' ...
                Stm.Descript '_Run' num2str(1)];
        end
    else
        FileName=['Log_NODAS_' LogFn '_' ...
            Stm.Descript '_Run' num2str(1)];
    end
    warning off;
    if TestRunstimWithoutDAS; cd ..;end
    StimObj.Stm=Stm;
    % 1st is PreStim, last is PostStim
    Log.FixPerc=100*(Par.FixInOutTime(:,1)./sum(Par.FixInOutTime,2));
    
    % copy the originally used files
    if ~RunParStim_Saved
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
        % stimulus
        if RetMapStimuli
            save('RetMap_Stimulus','ret_vid');
        end
        RunParStim_Saved=true;
    end
    
    % save mat and json files
    if ~TestRunstimWithoutDAS && ~json_done 
        % save json file ===========
        Par.jf.Project      = 'FigureGround';
        if strcmp(Par.SetUp,'NIN')
            Par.jf.Method   = 'EPHYS';
        else
            Par.jf.Method   = 'MRI';
        end
        Par.jf.Protocol     = '17.25.01';
        Par.jf.Dataset      = Par.LogFolder(...
            find(Par.LogFolder=='\',1,'last')+1:end);
        Par.jf.Date         = datestr(now,'yyyymmdd');
        Par.jf.Subject      = Par.MONKEY;
        Par.jf.Researcher   = 'ChrisKlink';
        Par.jf.Setup        = Par.SetUp;
        Par.jf.Group        = 'awake';
        Par.jf.Stimulus     = Stm.Descript;
        Par.jf.LogFolder    = [Par.MONKEY '_' DateString];
        Par.jf.logfile_name = FileName; %%%%%%%%
        Par.jf.fixperc      = Log.FixPerc;
        Par.jf.RunNumber	= 'XXX';
        Par.jf.QualityAsses = '10';
        % give the possibility to change
        % only when at scanner
        if strcmp(Par.SetUp, 'Spinoza_3T') || strcmp(Par.SetUp, 'NIN')
            json_answer = inputdlg(...
                {'Project','Method','Protocol',...
                'Dataset','Subject','Researcher',...
                'Setup','Group','Run','Quality (0-10)'},...
                'JSON SPECS',1,...
                {Par.jf.Project,Par.jf.Method,Par.jf.Protocol,...
                Par.jf.Dataset,Par.jf.Subject,Par.jf.Researcher,...
                Par.jf.Setup,Par.jf.Group,Par.jf.RunNumber,...
                Par.jf.QualityAsses},'on');
            Par.jf.Project      = json_answer{1};
            Par.jf.Method       = json_answer{2};
            Par.jf.Protocol     = json_answer{3};
            Par.jf.Dataset      = json_answer{4};
            Par.jf.Subject      = json_answer{5};
            Par.jf.Researcher   = json_answer{6};
            Par.jf.Setup        = json_answer{7};
            Par.jf.Group        = json_answer{8};
            Par.jf.RunNumber    = json_answer{9};
            Par.jf.QualityAsses = json_answer{10};
        end
        json.project.title      = Par.jf.Project;
        json.project.method     = Par.jf.Method;
        json.dataset.protocol   = Par.jf.Protocol;
        json.dataset.name       = Par.jf.Dataset;
        json.session.date       = Par.jf.Date;
        json.session.subjectId  = Par.jf.Subject;
        json.session.investigator = Par.jf.Researcher;
        json.session.setup      = Par.jf.Setup;
        json.session.group      = Par.jf.Group;
        json.session.stimulus   = Par.jf.Stimulus;
        json.session.logfile    = Par.jf.logfile_name;
        json.session.logfolder  = Par.jf.LogFolder;
        json.session.fixperc    = Par.jf.fixperc;
        json.session.run        = Par.jf.RunNumber;
        json.session.quality    = Par.jf.QualityAsses;
        
        json_done=true;
    end
    
    if ~TestRunstimWithoutDAS
        % save log mat-file ============
        temp_hTracker=Par.hTracker;
        Par=rmfield(Par,'hTracker');
        save(FileName,'Log','Par','StimObj');
        Par.hTracker = temp_hTracker;
    end
    
    
    % write some stuff to a text file as well
    if ~TestRunstimWithoutDAS
        fid=fopen([FileName '.txt'],'w');
        fprintf(fid,['Runstim: ' Par.RUNFUNC '\n']);
        fprintf(fid,['StimSettings: ' Par.STIMSETFILE '\n']);
        fprintf(fid,['ParSettings: ' Par.PARSETFILE '\n\n']);
        fprintf(fid,['Stimulus: ' Stm.Descript '\n\n']);
        
        fprintf(fid,['Fixation perc over run (inc. pre/post): ' num2str(mean(Log.FixPerc)) '\n']);
        fprintf(fid,['Fixation perc over run (exc. pre/post): ' num2str(mean(Log.FixPerc(2:end-1))) '\n']);
        for i=1:length(Log.FixPerc)
            if i==1
                fprintf(fid,['Fixation perc PreStim: ' ...
                    num2str(Log.FixPerc(i)) '\n']);
            elseif i==length(Log.FixPerc)
                fprintf(fid,['Fixation perc PostStim: ' ...
                    num2str(Log.FixPerc(i)) '\n']);
            else
                fprintf(fid,['Fixation perc cycle ' num2str(i-1) ': ' ...
                    num2str(Log.FixPerc(i)) '\n']);
            end
        end
        fprintf(fid,['\nTotal reward: ' num2str(Log.TotalReward) '\n']);
        fclose(fid);
    end
    cd(Par.ExpFolder)
    
    if TestRunstimWithoutDAS; cd Experiment;end
    warning on;
    
    % if running without DAS close ptb windows
    if TestRunstimWithoutDAS
        Screen('closeall');
    end
end

%% diagnostics to cmd -----------------------------------------------------
if ~Par.ESC && ~TestRunstimWithoutDAS
    GrandTotalReward=GrandTotalReward+Log.TotalReward;
    fprintf(['Total reward this run: ' num2str(Log.TotalReward) '\n']);
    fprintf(['Total reward thusfar: ' num2str(GrandTotalReward) '\n']);
    fprintf(['Total time-out this run: ' num2str(Log.TimeOutThisRun) '\n']);
    fprintf(['Total time-out thusfar: ' num2str(Log.TotalTimeOut) '\n']);
    fprintf(['Fixation percentage: ' num2str(nanmean(Log.FixPerc)) '\n']);
    
    CollectPerformance{StimLoopNr,1} = Stm.Descript;
    CollectPerformance{StimLoopNr,2} = nanmean(Log.FixPerc);
    CollectPerformance{StimLoopNr,3} = nanstd(Log.FixPerc)./sqrt(length(Log.FixPerc));
    CollectPerformance{StimLoopNr,4} = Log.TotalReward;
    CollectPerformance{StimLoopNr,5} = Log.TimeOutThisRun;
elseif Par.ESC && ~LastRewardAdded && ~TestRunstimWithoutDAS
    GrandTotalReward=GrandTotalReward+Log.TotalReward;
    fprintf(['Total reward this run: ' num2str(Log.TotalReward) '\n']);
    fprintf(['Total reward thusfar: ' num2str(GrandTotalReward) '\n']);
    fprintf(['Total time-out this run: ' num2str(Log.TimeOutThisRun) '\n']);
    fprintf(['Total time-out thusfar: ' num2str(Log.TotalTimeOut) '\n']);
    fprintf(['Fixation percentage: ' num2str(nanmean(Log.FixPerc)) '\n']);
    
    CollectPerformance{StimLoopNr,1} = Stm.Descript;
    CollectPerformance{StimLoopNr,2} = nanmean(Log.FixPerc);
    CollectPerformance{StimLoopNr,3} = nanstd(Log.FixPerc);
    CollectPerformance{StimLoopNr,4} = Log.TotalReward;
    CollectPerformance{StimLoopNr,5} = Log.TimeOutThisRun;
    LastRewardAdded=true;
end
if Par.RespIndLeds; dasbit(Par.LED_B(1),0);dasbit(Par.LED_B(2),0);end % LEDS off

%% PostExpProcessing ======================================================
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);

fprintf('\n\n------------------------------\n');
fprintf('Experiment ended as planned\n');
fprintf('------------------------------\n');

% close audio devices
for i=1:length(Par.FeedbackSoundSnd)
    if ~isnan(Par.FeedbackSoundSnd(i).h)
        PsychPortAudio('Close', Par.FeedbackSoundSnd(i).h);
    end
end

if TestRunstimWithoutDAS
    sca; cd Experiment; rmpath(genpath(cd));
end

%% Process performance ====================================================
if ~isempty(CollectPerformance) && ~TestRunstimWithoutDAS
    ColPerf=[];
    
    cd(LogPath);
    fid2=fopen(['SUMMARY_' LogFn '.txt'],'w');
    fprintf(fid2,['Runstim: ' Par.RUNFUNC '\n']);
    fprintf(fid2,['StimSettings: ' Par.STIMSETFILE '\n']);
    fprintf(fid2,['ParSettings: ' Par.PARSETFILE '\n\n']);
    
    for rr = 1:size(CollectPerformance,1)
        fprintf([num2str(rr) ': Performance for ' CollectPerformance{rr,1} ' = ' num2str(CollectPerformance{rr,2}) ' %%\n']);
        fprintf(fid2,[num2str(rr) ': Performance for ' CollectPerformance{rr,1} ' = ' num2str(CollectPerformance{rr,2}) ' %%\n']);
        ColPerf=[ColPerf; CollectPerformance{rr,2}];
    end
    fprintf(['\nAverage performance: ' num2str(nanmean(ColPerf)) '%% (std: ' num2str(nanstd(ColPerf)) ' %%)\n']);
    fprintf(['Total reward: ' num2str(GrandTotalReward) ' s\n']);
    fprintf(fid2,['Average performance: ' num2str(nanmean(ColPerf)) '%% (std: ' num2str(nanstd(ColPerf)) ' %%)\n']);
    fprintf(fid2,['Total reward: ' num2str(GrandTotalReward) ' s']);
    fclose(fid2);
    
    % plot performance
    if Par.PlotPerformance
        if size(CollectPerformance,1) > 15
            xtick_use = 2:2:size(CollectPerformance,1);
        else
            xtick_use = 1:size(CollectPerformance,1);
        end
        
        figperf = figure('units','pixels','outerposition',[0 0 1000 1000]);
        subplot(4,4,1:3); hold on; box on;
        errorbar(1:size(CollectPerformance,1),...
            [CollectPerformance{:,2}],[CollectPerformance{:,3}],...
            'ko','MarkerFaceColor','k','MarkerSize',6,'linestyle','none')
        set(gca,'ylim',[0 100],'xlim',[0 size(CollectPerformance,1)+1],...
            'xtick', xtick_use,'FontSize',11)
        tt=title(['Performance: ' Par.MONKEY '_' Par.STIMSETFILE ...
            '_' DateString],'interpreter','none');
        %xx=xlabel('Stimulus (chronol. order)');
        yy=ylabel('Fixation (%)');
        set(tt,'FontSize', 12);
        %set(xx,'FontSize', 12);
        set(yy,'FontSize', 12);
        
        subplot(4,4,5:7); hold on; box on;
        plot(1:size(CollectPerformance,1),[CollectPerformance{:,4}],...
            'ko','MarkerFaceColor','k','MarkerSize',6)
        set(gca,'xlim',[0 size(CollectPerformance,1)+1],...
            'xtick', xtick_use,'FontSize',11)
        %     tt=title(['Reward (s): ' Par.MONKEY '_' Par.STIMSETFILE ...
        %         '_' DateString],'interpreter','none');
        %xx=xlabel('Stimulus (chronol. order)'); yy=ylabel('Reward (s)');
        %xx=xlabel('Stimulus (chronol. order)');
        yy=ylabel('Reward (s)');
        %set(tt,'FontSize', 12);
        %set(xx,'FontSize', 12);
        set(yy,'FontSize', 12);
        
        subplot(4,4,9:11); hold on; box on;
        for sn=1:size(CollectPerformance,1)
            CP{sn}=[num2str(sn) ': ' CollectPerformance{sn,1}];
        end
        plot(1:size(CollectPerformance,1),cumsum([CollectPerformance{:,4}]),...
            'ro-','MarkerFaceColor','r','MarkerSize',6)
        set(gca,'xlim',[0 size(CollectPerformance,1)+1],...
            'xtick', xtick_use,'FontSize',11)
        %     tt=title(['Reward (s): ' Par.MONKEY '_' Par.STIMSETFILE ...
        %         '_' DateString],'interpreter','none');
        %xx=xlabel('Stimulus (chronol. order)');
        yy=ylabel('Cumul. reward (s)');
        %set(tt,'FontSize', 12);
        %set(xx,'FontSize', 12);
        set(yy,'FontSize', 12);
        
        subplot(4,4,13:15); hold on; box on;
        plot(1:size(CollectPerformance,1),[CollectPerformance{:,5}],...
            'ko','MarkerFaceColor','k','MarkerSize',6)
        set(gca,'xlim',[0 size(CollectPerformance,1)+1],...
            'xtick', xtick_use,'FontSize',11)
        %     tt=title(['Time-outs (s): ' Par.MONKEY '_' Par.STIMSETFILE ...
        %         '_' DateString],'interpreter','none');
        xx=xlabel('Stimulus (chronol. order)');
        yy=ylabel('Time-outs (s)');
        %set(tt,'FontSize', 12);
        set(xx,'FontSize', 12);
        set(yy,'FontSize', 12);
        
        subplot(4,4,[4,8,12,16])
        set(gca,'XColor','w','YColor','w','xtick',[],'ytick',[]);
        tb=annotation('textbox',[.75 .1 .15 .8]);
        set(tb,'BackGroundColor','w','EdgeColor','none','String',...
            CP,'FontSize',10,'interpreter','none')
        set(figperf,'Color','w');
        
        %         saveas(figperf,['PERFORM_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString],'fig');
        %         export_fig(['PERFORM_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString],...
        %             '-pdf','-nocrop',figperf);
        saveas(figperf,['PERFORM_' LogFn],'fig');
        export_fig(['PERFORM_' LogFn],'-pdf','-nocrop',figperf);
        close(figperf);
    end
    save(['PERFORM_' LogFn],'CollectPerformance');
    cd(Par.ExpFolder)
end
clear Log
Par=Par_BU;

%% Standard functions called throughout the runstim =======================
% create fixation window around target
    function DefineEyeWin
        FIX = 0;  %this is the fixation window
        TALT = 1; %this is an alternative/erroneous target window --> not used
        TARG = 2; %this is the correct target window --> not used
        Par.WIN = [...
            Stm.Center(Par.PosNr,1), ...
            -Stm.Center(Par.PosNr,2), ...
            Stm.FixWinSizePix(1), ...
            Stm.FixWinSizePix(2), FIX]';
        refreshtracker( 1) %clear tracker screen and set fixation and target windows
        SetWindowDas %set das control thresholds using global parameters : Par
    end
% draw fixation
    function DrawFix
        % fixation area
        rect=[...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm.FixDotSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm.FixDotSizePix/2];
        rect2=[...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm.FixDotSurrSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm.FixDotSurrSizePix/2, ...
            Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm.FixDotSurrSizePix/2, ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm.FixDotSurrSizePix/2];
        
        Screen('FillOval',Par.window,Par.BG.*Par.ScrWhite,rect2);
        Screen('FillOval',Par.window,Par.CurrFixCol,rect);
        
        cen = [Stm.Center(Par.PosNr,1)+Par.ScrCenter(1), ...
            Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)];
    end
% draw handindicator
    function DrawHandIndicator
        if any(any(Par.RespIndPos)) % stimuli not centered
            cen = [Par.ScrCenter(1),Par.ScrCenter(2)];
            cen1 = [Par.RespIndPos(1,1)*Par.PixPerDeg+Par.ScrCenter(1), ...
                Par.RespIndPos(1,2)*Par.PixPerDeg+Par.ScrCenter(2)];
            cen2 = [Par.RespIndPos(2,1)*Par.PixPerDeg+Par.ScrCenter(1), ...
                Par.RespIndPos(2,2)*Par.PixPerDeg+Par.ScrCenter(2)];
        else % stimulus centered (but can be cycled)
            cen = [Stm.Center(Par.PosNr,1)+Par.ScrCenter(1), ...
                Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)];
            cen1=cen;cen2=cen;
        end
        
        if strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            if Par.ResponseState == Par.RESP_STATE_DONE && ...
                    ~Par.CanStartTrial(Par) && ...
                    GetSecs >= Par.ResponseStateChangeTime + 500/1000
                if Par.DrawBlockedInd && (Par.TrialNeeds.LeversAreDown && any(Par.LeverIsUp))
                    Screen('FillOval',Par.window, Par.BlockedIndColor.*Par.ScrWhite, ...
                        [cen,cen] + Par.RespIndSizePix*blocked_circle)
                end
            elseif (Par.ResponseState == Par.RESP_STATE_WAIT || ...
                    Par.ResponseState == Par.RESP_STATE_GO) && ...
                    Par.ResponseSide == 1
                Screen('FillPoly',Par.window, Par.RespIndColor(1,:).*Par.ScrWhite, ...
                    [cen1;cen1;cen1;cen1] + Par.RespIndSizePix*left_square)
                if Par.RespIndLeds; dasbit(Par.LED_B(Par.ResponseSide),1); end % LED on
            elseif (Par.ResponseState == Par.RESP_STATE_WAIT || ...
                    Par.ResponseState == Par.RESP_STATE_GO) && ...
                    Par.ResponseSide == 2
                Screen('FillPoly',Par.window, Par.RespIndColor(2,:).*Par.ScrWhite, ...
                    [cen2;cen2;cen2;cen2] + Par.RespIndSizePix*right_diamond)
                if Par.RespIndLeds; dasbit(Par.LED_B(Par.ResponseSide),1); end % LED on
            elseif Par.ResponseState == Par.RESP_STATE_DONE && ...
                    Par.CurrResponseSide == 1
                if Par.RespIndLeds; dasbit(Par.LED_B(1),0);dasbit(Par.LED_B(2),0);end % LEDS off
                %                 Screen('FillPoly',Par.window, Par.RespIndColor(1,:).*Par.ScrWhite, ...
                %                     [cen1;cen1;cen1;cen1] + Par.RespIndSizePix*left_square)
            elseif Par.ResponseState == Par.RESP_STATE_DONE && ...
                    Par.CurrResponseSide == 2
                if Par.RespIndLeds; dasbit(Par.LED_B(1),0);dasbit(Par.LED_B(2),0);end % LEDS off
                %                 Screen('FillPoly',Par.window, Par.RespIndColor(2,:).*Par.ScrWhite, ...
                %                     [cen2;cen2;cen2;cen2] + Par.RespIndSizePix*right_diamond)
            end
        end
    end
% draw "go bar"
    function DrawGoBar
        if Par.ResponseSide==0
            return
        end
        % Target bar
        %if ~Par.Orientation(Par.CurrOrient)
        if Par.ResponseState == Par.RESP_STATE_GO  %horizontal
            rect=[...
                Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)-Par.GoBarSizePix(1)/2, ...
                Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)-Par.GoBarSizePix(2)/2, ...
                Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)+Par.GoBarSizePix(1)/2, ...
                Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)+Par.GoBarSizePix(2)/2];
            Screen('FillRect',Par.window,Par.GoBarColor.*Par.ScrWhite,rect);
            
        elseif Par.ResponseState == Par.RESP_STATE_WAIT %vertical
            rect=[...
                Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)-Par.GoBarSizePix(2)/2, ... left
                Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)-Par.GoBarSizePix(1)/2, ... top
                Stm.Center(Par.PosNr,1)+Par.ScrCenter(1)+Par.GoBarSizePix(2)/2, ... right
                Stm.Center(Par.PosNr,2)+Par.ScrCenter(2)+Par.GoBarSizePix(1)/2];
            Screen('FillRect',Par.window,Par.GoBarColor.*Par.ScrWhite,rect);
        end
    end
% draw stimuli
    function DrawUniformBackground
        % Background
        Screen('FillRect',Par.window,ceil(Par.BG.*Par.ScrWhite));
    end
% auto-dim the screen if hand is out
    function AutoDim
        if Par.HandOutDimsScreen && (...
                (strcmp(Par.HandInBothOrEither,'Both') && ~all(Par.HandIsIn)) || ...
                (strcmp(Par.HandInBothOrEither,'Either') && ~any(Par.HandIsIn)) ...
                )
            if ~any(Par.HandIsIn) % no hands in
                if size(Par.HandOutDimsScreen_perc,2) == 2
                    Screen('FillRect',Par.window,...
                        [0 0 0 (Par.HandOutDimsScreen_perc(2))].*Par.ScrWhite,....
                        [Par.wrect(1:2) Par.wrect(3:4)+1]);
                else
                    Screen('FillRect',Par.window,...
                        [0 0 0 (Par.HandOutDimsScreen_perc(1))].*Par.ScrWhite,....
                        [Par.wrect(1:2) Par.wrect(3:4)+1]);
                end
            else % a hand in
                Screen('FillRect',Par.window,...
                    [0 0 0 (Par.HandOutDimsScreen_perc(1))].*Par.ScrWhite,....
                    [Par.wrect(1:2) Par.wrect(3:4)+1]);
            end
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
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type=['Pos' num2str(Par.PosNr)];
            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
            DefineEyeWin;
        end
    end
% check for key-presses
    function CheckKeys
        % check
        [Par.KeyIsDown,Par.KeyTime,KeyCode]=KbCheck; %#ok<*ASGLU>
        InterpretKeys(KeyCode)
    end
% interpret key presses
    function InterpretKeys(KeyCode)
        % Par.KeyDetectedInTrackerWindow is true when key press is detected
        % in the Tracker window, false if it's not. Allows key-press isolation
        
        % interpret key presses
        if Par.KeyIsDown && ~Par.KeyWasDown
            Key=KbName(KbName(KeyCode));
            if isscalar(KbName(KbName(KeyCode)))
                switch Key
                    case Par.KeyEscape
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            Par.ESC = true;
                        elseif TestRunstimWithoutDAS
                            Par.ESC = true;
                        end
                    case Par.KeyTriggerMR
                        Log.MRI.TriggerReceived = true;
                        Log.MRI.TriggerTime = ...
                            [Log.MRI.TriggerTime; Par.KeyTime];
                        Log.nEvents=Log.nEvents+1;
                        Log.Events(Log.nEvents).type='MRITrigger';
                        Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                        Log.Events(Log.nEvents).StimName = [];
                        if strcmp(Par.SetUp,'NIN') % send start bit to sync ephys system
                            %dasword(00000);
                            send_serial_data(0);
                            WordsSent=WordsSent+1; %keep track of how many words are sent so we back-check TDT against the log
                            Log.Words(WordsSent)=00000; %collect all the words that are sent to TDT
                        end
                    case Par.KeyJuice
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            Par.ManualReward = true;
                            Log.ManualRewardTime = ...
                                [Log.ManualRewardTime; Par.KeyTime];
                        end
                    case Par.KeyStim
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.ToggleHideStim
                                Par.ToggleHideStim = true;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='StimOff';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                            else
                                Par.ToggleHideStim = false;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='StimOn';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                            end
                        end
                    case Par.KeyFix
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.ToggleHideFix
                                Par.ToggleHideFix = true;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='FixOff';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                            else
                                Par.ToggleHideFix = false;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='FixOn';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                            end
                        end
                    case Par.KeyPause
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.Pause
                                Par.Pause=true;
                                fprintf('Time-out ON\n');
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='PauseOn';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                                Par.PauseStartTime=Par.KeyTime;
                            else
                                Par.Pause=false;
                                Par.PauseStopTime=Par.KeyTime-Par.PauseStartTime;
                                fprintf(['Time-out OFF (' num2str(Par.PauseStopTime) ' s)\n']);
                                Log.TotalTimeOut = Log.TotalTimeOut+Par.PauseStopTime;
                                Log.TimeOutThisRun=Log.TimeOutThisRun+Par.PauseStopTime;
                                Log.nEvents=Log.nEvents+1;
                                Log.Events(Log.nEvents).type='PauseOff';
                                Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                                Log.Events(Log.nEvents).StimName = [];
                            end
                        end
                    case Par.KeyRewTimeSet
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            Par.RewardTime=Par.RewardTimeSet;
                            Par.Times.Targ = Par.RewardFixHoldTime;
                            fprintf('Reward schedule set as defined in ParSettings\n');
                        end
                    case Par.KeyShowRewTime
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            fprintf('Reward amount (s):\n');
                            Par.RewardTime
                            fprintf('Fix time to get reward:\n' );
                            Par.Times.Targ
                        end
                    case Par.KeyCyclePos
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                if Par.ToggleCyclePos
                                    Par.ToggleCyclePos = false;
                                    fprintf('Toggle automatic position cycling: OFF\n');
                                else
                                    Par.ToggleCyclePos = true;
                                    fprintf('Toggle automatic position cycling: ON\n');
                                end
                            end
                        end
                    case Par.KeyLockPos
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.PositionLocked=true;
                                fprintf('Fix position LOCKED\n');
                            else
                                Par.PositionLocked=false;
                                fprintf('Fix position UNLOCKED\n');
                            end
                        end
                    case Par.Key1
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = '1';
                            end
                        end
                    case Par.Key2
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = '2';
                            end
                        end
                    case Par.Key3
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = '3';
                            end
                        end
                    case Par.Key4
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = '4';
                            end
                        end
                    case Par.Key5
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = '5';
                            end
                        end
                    case Par.KeyNext
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.PositionLocked
                                Par.SwitchPos = true;
                                Par.WhichPos = 'Next';
                                % case Par.KeyPrevious
                                % Par.SwitchPos = true;
                                % Par.WhichPos = 'Prev';
                            end
                        end
                    case Par.KeyLeftResp
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            fprintf('LEFT response indicators only\n');
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='LeftRespOnly';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                            Log.Events(Log.nEvents).StimName = [];
                            Par.RespProbSetting=1;
                            Par.ForceRespSide = true;
                        end
                    case Par.KeyRightResp
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            fprintf('RIGHT response indicators only\n');
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='RightRespOnly';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                            Log.Events(Log.nEvents).StimName = [];
                            Par.RespProbSetting=2;
                            Par.ForceRespSide = true;
                        end
                    case Par.KeyRandResp
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            fprintf('PROBABLISTIC response indicators\n');
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='RandRespInd';
                            Log.Events(Log.nEvents).t=Par.KeyTime-Par.ExpStart;
                            Log.Events(Log.nEvents).StimName = [];
                            Par.RespProbSetting=0;
                            Par.ForceRespSide = true;
                        end
                    case Par.KeyBeam
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            Par.KeyBeamInd = Par.KeyBeamInd+1;
                            if Par.KeyBeamInd > size(Par.KeyBeamStates,1)-1
                                Par.KeyBeamInd =  Par.KeyBeamInd - ...
                                    (size(Par.KeyBeamStates,1)-1);
                            end
                            switch Par.KeyBeamInd
                                case 1
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - TRIAL & FIX need hand in\n']);
                                case 2
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - ONLY TRIAL needs hand in\n']);
                                case 3
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - ONLY FIX needs hand in\n']);
                                case 4
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - TRIAL & FIX need hand in\n']);
                                case 5
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - TRIAL & FIX need hand in\n']);
                                case 6
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - ONLY TRIAL needs hand in\n']);
                                case 7
                                    fprintf(['BEAMSTATE: ' Par.KeyBeamStates{Par.KeyBeamInd+1,1} ...
                                        ' - ' Par.KeyBeamStates{Par.KeyBeamInd+1,2} ...
                                        ' - ONLY FIX needs hand in\n']);
                            end
                            Par.HandInBothOrEither = Par.KeyBeamStates{Par.KeyBeamInd+1,2};
                            Par.TrialNeeds.HandIsIn = Par.KeyBeamStates{Par.KeyBeamInd+1,3};
                            Par.FixNeeds.HandIsIn = Par.KeyBeamStates{Par.KeyBeamInd+1,4};
                            
                            % set-up function to check whether to draw fixation
                            if Par.FixNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Both')
                                Par.HideFix_BasedOnHandIn = @(Par) ~all(Par.HandIsIn);
                            elseif Par.FixNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Either')
                                Par.HideFix_BasedOnHandIn = @(Par) ~any(Par.HandIsIn);
                            else
                                Par.HideFix_BasedOnHandIn = @(Par) false;
                            end
                            
                            % functions for lever task
                            if Par.TrialNeeds.HandIsIn && Par.TrialNeeds.LeversAreDown % hands in / levers down
                                Par.CanStartTrial = @(Par) (all(Par.HandIsIn) && ~any(Par.LeverIsUp));
                            elseif Par.TrialNeeds.HandIsIn % only hands in
                                Par.CanStartTrial = @(Par) all(Par.HandIsIn);
                            elseif Par.TrialNeeds.LeversAreDown % only levers down
                                Par.CanStartTrial = @(Par) ~any(Par.LeverIsUp);
                            else % independent of hand and lever position
                                Par.CanStartTrial = @(Par) true;
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
        %check the incoming signal on DAS channel #3
        % NB dasgetlevel only starts counting at the third channel (#2)
        daspause(5);
        ChanLevels=dasgetlevel;
        Log.RespSignal = ChanLevels(Par.ConnectBox.PhotoAmp(:)-2);
        % dasgetlevel starts reporting at channel 3, so
        % subtract 2 from the channel you want (1 based)
        % Log.RespSignal is a vector with as many channels as are in use
        InterpretManual;
    end
% interpret manual response signal
    function InterpretManual
        % levels are different for differnet das cards
        if strcmp(computer,'PCWIN64')
            Threshold=40000;
        elseif strcmp(computer,'PCWIN')
            Threshold=2750;
        end
        
        Par.BeamWasBlocked = Par.BeamIsBlocked;
        % vector that tells us for all used channels whether blocked
        Par.BeamIsBlocked = Log.RespSignal < Threshold;
        
        % Log any changes
        if any(Par.BeamWasBlocked(:) ~= Par.BeamIsBlocked(:))
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type=...
                strcat('BeamStateChange ', mat2str(Par.BeamIsBlocked));
            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
            Par.HandIsIn =Par.BeamIsBlocked(Par.ConnectBox.PhotoAmp_HandIn);
            Par.LeverIsUp=Par.BeamIsBlocked(Par.ConnectBox.PhotoAmp_Levers);
            if any(Par.LeverIsUp ~= Par.LeverWasUp) && all(Par.LeverIsUp)
                % now both levers are up
                Par.BothLeversUp_time = GetSecs;
                Par.LeverWasUp = Par.LeverIsUp;
            elseif any(Par.LeverIsUp ~= Par.LeverWasUp) && ~all(Par.LeverIsUp)
                % something changed: both are not up
                Par.BothLeversUp_time = Inf;
                Par.LeverWasUp = Par.LeverIsUp;
            end
        end
        
        if ~strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            % interpret depending on response box type
            switch Par.ResponseBox.Type
                %                 case 'Beam'
                case 'Lift'
                    if ~any(Par.HandWasIn) && any(Par.HandIsIn) % from none to any
                        %fprintf('going from none to one\n')
                        Par.HandInPrev_Moment = Par.HandInNew_Moment; % the previous hand-in moment
                        Par.HandInNew_Moment = GetSecs; % current hand-in moment
                        Par.HandWasIn = Par.HandIsIn;
                    elseif any(Par.HandWasIn) && ~any(Par.HandIsIn)
                        %fprintf('all out now\n')
                        Par.HandInPrev_Moment = Par.HandInNew_Moment;
                        Par.HandWasIn = Par.HandIsIn;
                    elseif any(Par.HandWasIn) && any(Par.HandIsIn) && Par.RewardRunning
                        Par.HandInPrev_Moment = Par.HandInNew_Moment;
                    end
                    
                    if strcmp(Par.HandInBothOrEither, 'Both') && ...
                            all(Par.HandIsIn) % both in
                        if ~any(Par.HandWasIn)
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='BothHandsIn';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandWasIn=Par.HandIsIn;
                        end
                    elseif strcmp(Par.HandInBothOrEither, 'Either') && ...
                            any(Par.HandIsIn) % both in % at least one blocked
                        if ~all(Par.HandWasIn)
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            if Par.HandIsIn(1)
                                Log.Events(Log.nEvents).type='LeftHandIn';
                            else
                                Log.Events(Log.nEvents).type='RightHandIn';
                            end
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandWasIn=Par.HandIsIn;
                        end
                    elseif ~all(Par.HandIsIn)
                        if any(Par.HandWasIn)
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandsOut';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandWasIn=Par.HandIsIn;
                        end
                    end
            end
        end
    end
% give automated reward for fixation
    function GiveRewardAutoFix
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
        if ~isempty(Par.RewardFixMultiplier)
            if ~all(Par.HandIsIn) && any(Par.HandIsIn) % one hand in
                hig = Par.FixReward_HandInGain(1);
            elseif all(Par.HandIsIn) % both hands in
                hig = Par.FixReward_HandInGain(2);
            else % no hands in
                hig = 1;
            end
            Par.RewardTimeCurrent = hig * Par.RewardFixMultiplier * Par.RewardTimeCurrent;
            if Par.RewardFixMultiplier <= 0 % no reward given if true
                return
            end
        end
        
        if size(Par.Times.Targ,2)>1
            rownr= find(Par.Times.Targ(:,1)<Par.CorrStreakcount(2),1,'last');
            Par.Times.TargCurrent=Par.Times.Targ(rownr,2);
        else
            Par.Times.TargCurrent=Par.Times.Targ;
        end
        
        % only give reward when Reward time >0
        if Par.RewardTimeCurrent>0
            % Give the reward
            Par.RewardStartTime=GetSecs;
            if strcmp(computer,'PCWIN64')
                dasjuice(10); % 64bit das card
            else
                dasjuice(5) %old card dasjuice(5)
            end
            Par.RewardRunning=true;
            
            % Play back a sound
            if Par.RewardSound
                RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
                RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
                sound(RewY,Par.RewSndPar(1));
            end
            
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='RewardFix';
            Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = [];
        end
    end
% stop reward delivery
    function StopRewardIfNeeded
        if Par.RewardRunning && GetSecs >= ...
                Par.RewardStartTime+Par.RewardTimeCurrent
            dasjuice(0);
            Par.RewardRunning=false;
            Log.TotalReward = Log.TotalReward+Par.RewardTimeCurrent;
            %Par.ResponseSide = 0;
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='RewardStopped';
            Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = [];
        end
    end
% give automated reward for task
    function GiveRewardAutoTask
        if Par.Rew_BasedOnHandIn(Par) && ~Par.Pause
            if ~isempty(Par.RewardTaskMultiplier)
                Par.RewardTimeCurrent = Par.RewardTaskMultiplier * Par.RewardTime;
            else
                Par.RewardTimeCurrent = Par.RewardTime;
            end
            % gain for which lever is used
            if isfield(Par,'RespLeverGain')
                if any(Par.LeverIsUp) && ~all(Par.LeverIsUp) % only one up
                    Par.RewardTimeCurrent  = Par.RespLeverGain(...
                        logical(Par.LeverIsUp))*Par.RewardTimeCurrent;
                end
            end
            % gain for having hands in (when defined)
            if isfield(Par,'TaskReward_HandInGain')
                if any(Par.HandIsIn) && ~all(Par.HandIsIn) % only hand in
                    Par.RewardTimeCurrent  = Par.TaskReward_HandInGain(1)*Par.RewardTimeCurrent;
                elseif all(Par.HandIsIn) % both hands in
                    Par.RewardTimeCurrent  = Par.TaskReward_HandInGain(2)*Par.RewardTimeCurrent;
                end
            end
            % Give the reward
            if Par.RewardTimeCurrent>0
                Par.RewardStartTime=GetSecs;
                if strcmp(computer,'PCWIN64')
                    dasjuice(5.1); % 64bit das card
                else
                    dasjuice(5) %old card dasjuice(5)
                end
                Par.RewardRunning=true;
                
                % Play back a sound
                if Par.RewardSound
                    RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
                    RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
                    sound(RewY,Par.RewSndPar(1));
                end
                
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='RewardAutoTask';
                Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
            end
        end
    end
% give automated reward for hand in
    function GiveRewardAutoHandIn
        Par.RewardTimeCurrent = Par.RewardForHandsIn_Quant(sum(Par.HandIsIn));
        if ~all(Par.HandIsIn) && any(Par.HandIsIn) % only one hand in
            Par.RewardTimeCurrent = ...
                Par.RewardForHandsIn_MultiplierPerHand(Par.HandIsIn)*Par.RewardTimeCurrent;
        end
        % Give the reward
        if Par.RewardTimeCurrent>0
            Par.RewardStartTime=GetSecs;
            Par.RewHandStart=Par.RewardStartTime;
            if strcmp(computer,'PCWIN64')
                dasjuice(10); % 64bit das card
            else
                dasjuice(5) %old card dasjuice(5)
            end
            Par.RewardRunning=true;
            
            % Play back a sound
            if Par.RewardSound
                RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
                RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
                sound(RewY,Par.RewSndPar(1));
            end
            
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='RewardAutoHand';
            Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = [];
        end
    end
% give manual reward
    function GiveRewardManual
        Par.RewardTimeCurrent = Par.RewardTimeManual;
        % Give the reward
        Par.RewardStartTime=GetSecs;
        Par.RewardRunning=true;
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
        
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type='RewardMan';
        Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
        Log.Events(Log.nEvents).StimName = [];
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
        Log.nEvents=Log.nEvents+1;
        if Par.EyeRecTriggerLevel
            Log.Events(Log.nEvents).type='EyeRecOff';
        else
            Log.Events(Log.nEvents).type='EyeRecOn';
        end
        Log.Events(Log.nEvents).t=tEyeRecSet-Par.ExpStart;
        Log.Events(Log.nEvents).StimName = [];
    end
% check eye only (dascheck without tracker gui update)
    function [Hit, Time] = DasCheckEyeOnly %#ok<*DEFNU>
        Hit = LPStat(1);   %Hit yes or no
        Time = LPStat(0);  %time
        POS = dasgetposition();
        P = POS.*Par.ZOOM; %average position over window initialized in DasIni
        % eye position to global to allow logging
        Par.CurrEyePos = [POS(1) POS(2)];
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
% Update hand task state
    function UpdateHandTaskState(NewState)
        Par.ResponseState = NewState;
        Par.ResponseStateChangeTime = GetSecs;
        Log.nEvents=Log.nEvents+1;
        switch NewState
            case Par.RESP_STATE_WAIT
                Log.Events(Log.nEvents).type=...
                    'HandTaskState-Wait';
            case Par.RESP_STATE_GO
                Log.Events(Log.nEvents).type=...
                    'HandTaskState-Go';
            case Par.RESP_STATE_DONE
                Log.Events(Log.nEvents).type=...
                    'HandTaskState-Done';
            otherwise
                Log.Events(Log.nEvents).type=...
                    strcat('HandTaskState-Unknown-',NewState);
        end
        Log.Events(Log.nEvents).t=Par.ResponseStateChangeTime;
    end
% Change stimulus polarity
    function ChangePolarity(CurrPol)
        if CurrPol == 1
            CurrPol = 2;
        else
            CurrPol = 1;
        end
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type=...
            ['CurrPol_' num2str(CurrPol)];
        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
    end
% Refresh seed
    function GndTexNum=ChangeSeed(GndTexNum)
        NewGndTexNum = Ranint(Stm.Gnd(1).NumSeeds);
        while NewGndTexNum == GndTexNum
            NewGndTexNum = Ranint(Stm.Gnd(1).NumSeeds);
        end
        GndTexNum = NewGndTexNum;
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type=...
            ['Seed_' num2str(GndTexNum)];
        Log.Events(Log.nEvents).t=lft-Par.ExpStart;
    end
end
