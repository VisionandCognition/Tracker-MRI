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
end

%% Triggering =============================================================
Par.TR = 2.5; % Not important during training
Par.MRITriggeredStart = false;
Par.MRITrigger_OnlyOnce = true; 

%% Get stimulus info ======================================================
eval(Par.STIMSETFILE); % loads the chosen stimfile
Stm=StimObj.Stm;

StimObj.Stm.FixDotCol = [.3 .3 .3 ; .1 .1 .1]; %[RGB if not fixating; RGB fixating]

% overrule generic fixation window
Par.FixWinSize = Stm.FixWinSize; % [1.5 1.5]; % [W H] in deg 

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
    Screen('GetFlipInterval',Par.window,100,[],[]);
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
Par.TargetB = 2;
Par.RewardB = 3;
%Par.SaccadeB = 4; done by DasControl
%Par.TrialB = 5;   done by DasControl
Par.MicroB = 6;
Par.CorrectB = 7;

%% Response box ===========================================================
Par.ResponseBox.Type='Beam'; % 'Beam' or'Lift'

%% connection box port assignment =========================================
Par.ConnectBox.PhotoAmp = [4 5]; % 2 photo-amps can be connected
Par.ConnectBox.PhotoAmp_used = 1; % vector with indeces to used channels
Par.ConnectBox.EyeRecStat = 6;

%% Reward scheme ==========================================================
Par.Reward = true; %boolean to enable reward stim bit or not

Par.RewardSound = false; % give sound feedback about reward
Par.RewSndPar = [44100 800 1]; % [FS(Hz) TonePitch(Hz) Amplitude]
Par.RewardFixFeedBack = true;

% Require hands in the box (reduces movement?)
Par.HandSignalBothOrEither = 'Both'; 

% Require hands in the box (reduces movement?)
% Needed for initiation of tracker since it's in the gui now
Par.RewNeedsHandInBox=false; % not used here
Par.StimNeedsHandInBox=false;
Par.FixNeedsHandInBox=false; % not used here
Par.HandOutDimsScreen = false;
Par.HandOutDimsScreen_perc = 0.9; %(0-1, fraction dimming)

Par.HandIsIn=false;

% duration matches 'open duration'
Par.RewardType = 2; % Duration: 0=fixed reward, 1=progressive, 2=stimulus dependent
switch Par.RewardType
    case 0
        Par.RewardTimeSet = 0.020;
    case 1
        % Alternatively use a progressive reward scheme based on the number of
        % preceding consecutive correct responses format as
        % rows stating: [nCorrectTrials RewardTime]
        Par.RewardTimeSet = [...
            0   0.040;...
            5   0.060;...
            10  0.100;...
            15  0.150;...
            20  0.200];
        % NB! this will be overruled once you manually set the reward time
        % with the slider in the Tracker window
    case 2
        Par.RewardTimeSet = 0.090; %no reward
end

Par.RewardTimeManual = 0.03; % amount of reward when given manually

% this section is useful fro rewarding fixation only
% it does not change anything when we're rewarding stim-choice
Par.RewardFixHoldTimeProg = true;
if Par.RewardFixHoldTimeProg
    Par.RewardFixHoldTime = [...
        0 2000;...
        5 1750;...
        10 1500;...
        20 1250;...
        30 1000;...
        ];
else
    Par.RewardFixHoldTime = 1000; %time to maintain fixation for reward
end

Par.RewardTime=Par.RewardTimeSet;
% can be zero for stimdependent but this will be solved in stimsettings & runstim

%% Create Eye-check windows based on stimulus positions ===================
for SetInitialWINs=1
    % The code below is preloaded and will be overwritten on stimulus basis
    % for every trial individually
    %example window types, should be replaced by your own control windows
    FIX = 0;  %this is the fixation window
    TAR1 = 1; %this is an alternative/erroneous target window
    TAR2 = 2; %this is the correct target window
    
    %Par.WIN = [xpos, ypos, pix width, pix height, window type]
    Par.WIN = [...
        0,  0, Par.PixPerDeg*Par.FixWdDeg, Par.PixPerDeg*Par.FixHtDeg, FIX; ...
        100, 100, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TAR1; ...
        -300, 300, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TAR2].';
    
    %when target and fixation windows change in position and dimension you will
    %have to call two functions. The first is to show their position on the tracker screen.
    %The second is to update das routines that detect eye movements entering
    %and leaving these windows
    % 1. ->refreshtracker( 1) %clear tracker screen and set fixation and target windows
    % 2. ->SetWindowDas %set das control thresholds using global parameters : Par
end

%% Trial count initial ====================================================
Par.Trlcount = 0; 
Par.Corrcount = 0;
Par.Misscount = 0;
Par.Slowcount = 0;
Par.CorrStreakcount = 0;

%% Keyboard initialization ================================================
for KeyboardSettings = 1
    Par.KeyEscape = KbName('Escape'); % allows breaking out of the experiment
    Par.KeyTriggerMR = KbName('t'); % MRI sends a sync pulse as a 't' keypress
    Par.KeyJuice = KbName('j'); % Manual juice reward
    Par.KeyStim = KbName('s'); % toggle stimulus on/off
    Par.KeyFix = KbName('f'); % toggle fix dot on/off
    Par.KeyPause = KbName('p'); % switch on/off stimuli & reward
    Par.KeyRewTimeSet = KbName('r'); % switch to reward timing as defined in ParSettings
    Par.KeyShowRewTime = KbName('w'); % Shows the current reward scheme 
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
    Par.KeyNext = KbName('n');
    Par.KeyCyclePos = KbName('0)'); % toggle cycle position automatically
    Par.KeyLockPos = KbName('l'); % lock current position (switching keys will have no effect)
    
    Par.PositionLocked=true;
end

%% Trial timing information ===============================================
for TimingSettings=1
    Par.Times.ToFix = Stm.PreFixT; %time allowed to enter fix window in ms
    Par.Times.Fix = Stm.FixT;  %Time in fixation window
    Par.Times.Stim = Stm.FixT+Stm.ReacT;  %Stimulus on time
    Par.Times.Targ = Stm.KeepFixT;  %Time to keep fixating after stim onset
    %Par.Times.TargCurrent = Par.Times.Targ;
    Par.Times.Rt = Stm.ReacT;  %Time allowed to make eye movement
    Par.Times.InterTrial = Stm.ISI; %intertrial time
    Par.Times.RndInterTrial = Stm.ISI_RAND; % maximum extra (random) ISI to break any possible rythm
        
    Par.Times.Sacc = Stm.SaccT; %max time to finish saccade
    Par.Times.Err = Stm.ErrT; %time to add to in RT-epoch after error
    % >> there is no 'ERROR' in this experiment
    % >> no target slection can be punished by re-entering the trial in the
    % list
    
    Par.Drum = true;     %drumming on or off, redoing error trials
    Par.DrumType = 3; %1=immediately repeat, 2=append to end, 3=insert randomly
    Par.isRunning = false;  %stimulus presentation off
    
    % This is not really used but required by Tracker ---------------------
    Par.Times.RndFix = 0; %max uniform random time to add to stimulus onset time
    Par.Times.RndStim = 0; %max uniform random time to add to stimulus display time
    Par.Times.RndTarg = 0; %max uniform random time to add to target onset time
    %----------------------------------------------------------------------
end

%% Tracker window control =================================================
Par.ZOOM = 0.6;   %control - cogent window zoom
Par.P1 = 1; Par.P2 = 1;