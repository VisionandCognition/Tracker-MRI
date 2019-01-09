function ParSettings

% ParSettings gives all parameters for the experiment in global Par
global Par
global StimObj

%% Setup ==================================================================
% Spinoza_Mock / Spinoza_3T / NIN
if strcmp(Par.ScreenChoice,'3T')
    Par.SetUp = 'Spinoza_3T';
elseif strcmp(Par.ScreenChoice,'Mock')
    Par.SetUp = 'Spinoza_MOCK';
elseif strcmp(Par.ScreenChoice,'NIN')
    Par.SetUp = 'NIN'; 
end

%% Triggering =============================================================
Par.TR = 2.5;
Par.MRITriggeredStart = false;
Par.MRITrigger_OnlyOnce = true;

%% Get stimulus info ======================================================
eval(Par.STIMSETFILE); % loads the chosen stimfile
Stm=StimObj.Stm;

% overwrites the stimsetting!
StimObj.Stm.FixDotCol = [.3 .3 .3 ; .1 .1 .1]; 
%[RGB if not fixating; RGB fixating]

% overrule generic fixation window
Par.FixWinSize = [1.5 1.5]; % [W H] in deg

%% Eyetracking parameters =================================================
Par.SetZero = false; %initialize zero key to not pressed
Par.SCx = 0.135; %initial scale in control window
Par.SCy = 0.135;
Par.OFFx = 0; %initial eye offset x => (center) of camera das output
Par.OFFy = 0; %initial eye offset y
Par.ScaleOff = [Par.OFFx; Par.OFFy; Par.SCx; Par.SCy]; 
%Offx, %Offy, Scalex, Scaley ; offset and scaling of eyechannels

%if using eyelink set to -1.0 else 1.0
Par.xdir = 1;
Par.ydir = 1;
Par.Sdx = 0; %2* standard error on eyechannels in pixels
Par.Sdy = 0;

Par.FixWdDeg = Par.FixWinSize(1);
Par.FixHtDeg = Par.FixWinSize(2);
Par.TargWdDeg = 2;
Par.TargHtDeg = 2;
Par.Bsqr = 0; %use square (1) or ellipse (0 )

Par.MousePress = 2; %0 left = 'normal', 1 middle = 'extend', 2 right = 'alt'
Par.NoiseUpdate = false; %show standard error of noise in fixation period
Par.NoiseUpdate = 0; %calculate noise level

%to use or not use the mouse
if ~exist('Par','var') || ~isfield(Par,'Mouserun')
    Par.Mouserun = 0;
    Par.MOff(1) = 0;  %mouse offsets
    Par.MOff(2) = 0;
end

% parameters for interfacing with ISCAN
Par.EyeRecAutoTrigger = false;
Par.EyeRecStatus = 0; % recording status initially to 'not recording'
Par.EyeRecTriggerLevel = 1; % 1 = stop recording, 0 = start recording

%% Screen info ============================================================
[ScrWidth, ScrHeight] = Screen('WindowSize',Par.ScrNr);
Par.HW = ScrWidth/2; %get half width of the screen
Par.HH = ScrHeight/2;
Par.ScrCenter = [Par.HW Par.HH];
[Par.ScreenWidthD2, Par.ScreenHeightD2] = Screen('DisplaySize',Par.ScrNr);

if strcmp(Par.SetUp,'NIN')
    Par.DistanceToScreen = 700; % distance to screen in mm
elseif strcmp(Par.SetUp,'Spinoza_MOCK')
    Par.DistanceToScreen = 1200; % distance to screen in mm
    % physical display size report is unreliable
    % these measures are taken by hand
    Par.ScreenWidthD2 = 600;
    Par.ScreenHeightD2 = 337.5;
elseif strcmp(Par.SetUp,'Spinoza_3T')
    Par.DistanceToScreen = 1300; % distance to screen in mm
    Par.ScreenWidthD2 = 705;
    Par.ScreenHeightD2 = 400;
end

Par.PixPerDeg = Par.HW/atand(Par.ScreenWidthD2/(2*Par.DistanceToScreen));

% CheckFlipRate
hz = Screen('NominalFrameRate', Par.ScrNr); RefRate100=hz*100;
[MeasuredFlip,nrValidSamples,stddev] = ...
    Screen('GetFlipInterval',Par.window,100,[],[]); %#ok<*ASGLU>
Rf = 1/MeasuredFlip;
if round(RefRate100/1000) ~= round(Rf/10)  %should be approximately the same
    disp(['Warning!: refreshrate not properly reported by PTB; ' ...
        num2str(RefRate100/100) 'Hz'] )
    Par.fliptime = MeasuredFlip*1000; %in ms
else
    Par.fliptime = 100000/RefRate100; %fliptime in ms
end
Par.fliptimeSec = Par.fliptime/1000;

Par.nFlipsRefresh=round(Stm(1).FlipTimePredef/Par.fliptimeSec);
if Par.nFlipsRefresh==0 || ~Stm(1).UsePreDefFlipTime
    Par.nFlipsRefresh=1;
end

Par.BG = Stm(1).BackColor; % get from stimulus file

Par.ScrWhite=WhiteIndex(Par.window);
Par.ScrBlack=BlackIndex(Par.window);

%% DAS parameters =========================================================
% Bit/port assignment
Par.ErrorB = 0;
Par.StimB = 1;
%Par.TargetB = 2; % check if they're really not used!
%Par.RewardB = 3; % check if they're really not used!
%Par.SaccadeB = 4; done by DasControl do not use for something else!!
%Par.TrialB = 5;   done by DasControl
Par.LED_B = [2 3]; % [1/LEFT 2/RIGHT]
Par.MicroB = 6;
Par.CorrectB = 7;

%% Response box ===========================================================
Par.ResponseBox.Type='Lift'; % 'Beam' or'Lift'

%% Response task ==========================================================
Par.ResponseBox.Task = 'DetectGoSignal';
%Par.ResponseBox.Task = 'Fixate';

Par.RESP_STATE_WAIT = 1; % Go signal not yet given
Par.RESP_STATE_GO = 2; % Go signal given
Par.RESP_STATE_DONE = 4;  % Go signal given and response no longer possible (hit or miss)

% Go-bar (vertical / horizontal target bar) -------------------------------
Gobar_length = 0.15; % .02
Par.GoBarSize = Gobar_length*[1, .25] + [0, 0.01]; % [length width] in deg
Par.GoBarColor = [0.6 0.7 0.7]; % [R G B] 0-1

% Color of the Response indicator (which hand)
Par.RespLeverMatters = true;
Par.RespIndColor = 0.1*[1 1 1;1 1 1]; % colors for the left and right target
Par.RespIndSize = 0.3;
Par.RespIndPos = [0 0; 0 0]; % deg
Par.RespIndLeds = false;

Par.DrawBlockedInd = false; % indicator to draw when a lever is still up
Par.BlockedIndColor = [.7 .7 .7];

Par.SwitchDur = 1500; % (200) duration of alternative orientation
Par.ResponseAllowed = [80 Par.SwitchDur+100]; % [after_onset after_offset] in ms
Par.PostErrorDelay = 3000; % extra wait time as punishment for error trials
Par.DelayOnMiss = 500; % extra wait time as punishment for miss trials 
Par.PostCorrectDelay = 100;

Par.NoIndicatorDuringPunishDelay=true;

Par.ProbSideRepeatOnCorrect =   0.50;
Par.ProbSideRepeatOnError =     0.50;
Par.ProbSideRepeatOnMiss =      0.50;
Par.ProbSideRepeatOnEarly =     0.50;
Par.MaxNumberOfConsecutiveErrors = 1000000;

Par.CatchBlock.do = true;
Par.CatchBlock.AfterNumberOfTrials = 1;
Par.CatchBlock.NoCorrectPerSideNeeded = 10;
Par.CatchBlock.StartWithCatch = true;

% set time-windows in which something can happen (ms)
% [baseduration_without_switch ... 
%  period_in_which_switch_randomly_occurs]
Par.EventPeriods = [100 500]; % Determines Go-bar onset (was 600 to 1600)

%% Connection box port assignment =========================================
Par.ConnectBox.PhotoAmp = [4 5 7 8];    % channels for photo-amps 
Par.ConnectBox.EyeRecStat = 6;          % channel for eye-tracker signal
Par.ConnectBox.PhotoAmp_Levers = 1:2;   % indeces to PhotoAmp channels
Par.ConnectBox.PhotoAmp_HandIn = 3:4;   % indeces to PhotoAmp channels

%% Reward scheme ==========================================================
Par.Reward = true; %boolean to enable reward stim bit or not
Par.RewardSound = false; % give sound feedback about reward
Par.RewSndPar = [44100 800 1]; % [FS(Hz) TonePitch(Hz) Amplitude]
Par.RewardFixFeedBack = true;

% RESP_CORRECT      = 1;
% RESP_FALSE        = 2;
% RESP_MISS         = 3;
% RESP_EARLY        = 4;
% RESP_BREAK_FIX    = 5;
Par.FeedbackSound = [true true false true false];
Par.FeedbackSoundPar = [ ...
    44100 800 1 0.03; ... CORRECT
    44100 300 1 0.03; ... FALSE
    44100 200 1 0.03; ... MISS
    44100 300 1 0.03; ... EARLY
    44100 400 1.5 0.03 ... FIXATION BREAK
    ];

% [FS(Hz) TonePitch(Hz) Amplitude Duration]
% duration matches 'open duration'

% Create audio buffers for low latency sounds 
% (they are closed in runstim cleanup) 
if any(Par.FeedbackSound)
    try
        InitializePsychSound; % init driver
        % if no speakers are connected, windows shuts down the snd device and
        % this will return an error
    catch
        fprintf('There were no audio devices detected. Is the output connected?\n');
    end
end
for i=1:size(Par.FeedbackSoundPar,1)
    Par.FeedbackSoundSnd(i).Wav=nan;
    Par.FeedbackSoundSnd(i).Fs=nan;
    Par.FeedbackSoundSnd(i).h = nan;
    if Par.FeedbackSound(i)
        RewT=0:1/Par.FeedbackSoundPar(i,1):Par.FeedbackSoundPar(i,4);
        Par.FeedbackSoundSnd(i).Wav=...
            Par.FeedbackSoundPar(i,3)*sin(2*pi*Par.FeedbackSoundPar(i,2)*RewT);
        Par.FeedbackSoundSnd(i).Fs=Par.FeedbackSoundPar(i,1);
        Par.FeedbackSoundSnd(i).h = PsychPortAudio('Open', [], [], 2,...
            Par.FeedbackSoundSnd(i).Fs, 1);
        PsychPortAudio('FillBuffer', Par.FeedbackSoundSnd(i).h, Par.FeedbackSoundSnd(i).Wav);
        clc;
    end
end

Par.RewardTaskMultiplier = 1.0;
Par.RewardFixMultiplier = 0.0;

% duration matches 'open duration'
Par.RewardType = 0; % Duration: 0=fixed reward, 1=progressive, 2=stimulus dependent
switch Par.RewardType
    case 0
        Par.RewardTimeSet = 0.040;
    case 1
        % Alternatively use a progressive reward scheme based on the number of
        % preceding consecutive correct responses format as
        % rows stating: [nCorrectTrials RewardTime]
        Par.RewardTimeSet = [...
            0   0.025;...
            5   0.1;...
            10  0.100;...
            15  0.150;...
            20  0.200];
        % NB! this will be overruled once you manually set the reward time
        % with the slider in the Tracker window
    case 2
        Par.RewardTimeSet = 0; %no reward
end

Par.RewardTimeManual = 0.02; % amount of reward when given manually

Par.RewardFixHoldTimeProg = true;
if Par.RewardFixHoldTimeProg
    Par.RewardFixHoldTime = [...
        0 1500;...
        5 1250;...   
        10 1000;...
        20 750;...
        30 500;...
        ];
else
    Par.RewardFixHoldTime = 1250; %time to maintain fixation for reward
end

Par.RewardTime=Par.RewardTimeSet;

%% Hand requirements ======================================================
% Require hands in the box (reduces movement?)
Par.HandInBothOrEither = 'Both'; % 'Both' or 'Either'

% Needed for initiation of tracker since it's in the gui now
Par.RewNeeds.HandIsIn =         false;
Par.StimNeeds.HandIsIn =        false;
Par.FixNeeds.HandIsIn =         false;
Par.TrialNeeds.HandIsIn =       false;   % manual response task
Par.TrialNeeds.LeversAreDown =  true;   % manual response task

Par.HandOutDimsScreen = false;
Par.HandOutDimsScreen_perc = 0.9; %(0-1, fraction dimming)

% set-up function to check whether to draw stimulus
if Par.StimNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Both')
    Par.HideStim_BasedOnHandIn = @(Par) ~all(Par.HandIsIn);
elseif Par.StimNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Either')
    Par.HideStim_BasedOnHandIn = @(Par) ~any(Par.HandIsIn);
else
    Par.HideStim_BasedOnHandIn = @(Par) false;
end

% set-up function to check whether to draw fixation
if Par.FixNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Both')
    Par.HideFix_BasedOnHandIn = @(Par) ~all(Par.HandIsIn);
elseif Par.FixNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Either')
    Par.HideFix_BasedOnHandIn = @(Par) ~any(Par.HandIsIn);
else
    Par.HideFix_BasedOnHandIn = @(Par) false;
end

% set-up function to check whether to allow reward
if Par.RewNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Both')
    Par.Rew_BasedOnHandIn = @(Par) all(Par.HandIsIn);
elseif Par.RewNeeds.HandIsIn && strcmp(Par.HandInBothOrEither,'Either')
    Par.Rew_BasedOnHandIn = @(Par) any(Par.HandIsIn);
else
    Par.Rew_BasedOnHandIn = @(Par) true;
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

Par.CorrectResponseGiven    = ...
    @(Par) Par.ResponseSide > 0 && Par.BeamIsBlocked(Par.ResponseSide);
Par.IncorrectResponseGiven  = ...
    @(Par) Par.ResponseSide > 0 && Par.BeamIsBlocked(mod(Par.ResponseSide,2)+1);

% Reward for keeping hand in the box
Par.RewardForHandsIn = false;
Par.RewardForHandsIn_Quant = [0.04 0.08]; % 1 hand, both hands
Par.RewardForHandsIn_MultiplierPerHand = [1.5 1]; % if only one hand in is rewarded [L R]
Par.RewardForHandIn_MinInterval = 2; %s

Par.RewardForHandIn_ResetIntervalWhenOut = false; 
Par.RewardForHandIn_MinIntervalBetween = 1; %s
% resets the timer for the next reward when the hand(s) are taken out 

% Fixation rewards are multiplied with this factor when hands are in
Par.FixReward_HandInGain = [1 1]; % one hand , both hands

%% Create Eye-check windows based on stimulus positions ===================
% The code below is preloaded and will be overwritten on stimulus basis
% for every trial individually
%example window types, should be replaced by your own control windows
FIX = 0;  %this is the fixation window
TALT = 1; %this is an alternative/erroneous target window
TARG = 2; %this is the correct target window

%Par.WIN = [xpos, ypos, pix width, pix height, window type]
Par.WIN = [...
    0,  0, Par.PixPerDeg*Par.FixWdDeg, Par.PixPerDeg*Par.FixHtDeg, FIX; ...
    200, 0, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TARG; ...
    -200, 0, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TALT].';

%when target and fixation windows change in position and dimension you will
%have to call two functions. The first is to show their position on the tracker screen.
%The second is to update das routines that detect eye movements entering
%and leaving these windows
% 1. ->refreshtracker( 1) %clear tracker screen and set fixation and target windows
% 2. ->SetWindowDas %set das control thresholds using global parameters : Par

%% Trial count inital =====================================================
Par.Trlcount = [0 0]; %[this_position total]
Par.CorrStreakcount = [0 0];

%% Keyboard initialization ================================================
Par.KeyEscape = KbName('Escape');   % allows breaking out of the experiment
Par.KeyTriggerMR = KbName('t');     % MRI sends a sync pulse as a 't' keypress
Par.KeyJuice = KbName('j');         % Manual juice reward
Par.KeyStim = KbName('s');          % toggle stimulus on/off
Par.KeyFix = KbName('f');           % toggle fix dot on/off
Par.KeyPause = KbName('p');         % switch on/off stimuli & reward
Par.KeyRewTimeSet = KbName('r');    % switch to reward timing as defined in ParSettings
Par.KeyShowRewTime = KbName('w');   % Shows the current reward scheme
% using the slider in tracker window overrules the initialize reward timing

% Change stim position
KbName('UnifyKeyNames');
Par.Key1 = KbName('1!');
Par.Key2 = KbName('2@');
Par.Key3 = KbName('3#');
Par.Key4 = KbName('4$');
Par.Key5 = KbName('5%');

% ARROW KEYS, adn 'Z' ARE USED BY TRACKER WINDOW
% Par.KeyNext = KbName('RightArrow');
% Par.KeyPrevious = KbName('LeftArrow');
Par.KeyNext = KbName('n');          % next position
Par.KeyCyclePos = KbName('0)');     % toggle cycle position automatically
Par.KeyLockPos = KbName('l');       % lock current position (switching keys will have no effect)
Par.PositionLocked=true;

Par.KeyBeam = KbName('b');          % cycle through possible beam requirements 
Par.KeyBeamInd = 0;
Par.KeyBeamStates = {...
    'BeamState','Both/Either','TrialNeedsHand','FixNeedsHand';...
    '1','Both',     1,1;...
    '2','Both',     1,0;...
    '3','Both',     0,1;...
    '4','Either',   1,1;...
    '5','Either',   1,0;...
    '6','Either',   0,1;...    
    '7','None',     0,0};

%% Trial timing information (CvdT) ========================================
% NB: Most of this is not used, but tracker may need it in initialization
Par.Times.ToFix = 0; %time to enter fix window in ms
Par.Times.Fix = 0;  %Time in fixation window
Par.Times.Stim = 0;  %Stimulus on time
Par.Times.Targ = Par.RewardFixHoldTime;  %Time to keep fixating after stim onset
Par.Times.TargCurrent = Par.Times.Targ;
Par.Times.Rt = 0;  %Time to make eye movement
Par.Times.InterTrial = 0; %intertrial time

Par.Times.RndFix = 0; %max uniform random time to add to stimulus onset time
Par.Times.RndStim = 0; %max uniform random time to add to stimulus display time
Par.Times.RndTarg = 0; %max uniform random time to add to target onset time

Par.Times.Sacc = 0; %max time to finish saccade
Par.Times.Err = 0; %time to add to in RT-epoch after error
%
Par.Drum = false;     %drumming on or off, redoing error trials
Par.DrumType = 1; %1=immediately repeat, 2=append to end, 3=insert randomly
Par.isRunning = false;  %stimulus presentation off

%% Tracker window control =================================================
Par.ZOOM = 0.6;   %control - cogent window zoom
Par.P1 = 1; Par.P2 = 1;

%% Logging ================================================================
Par.PlotPerformance = false;
% log folder should be defined in stimsettings
Par.LogFolder = Stm(1).LogFolder; 
