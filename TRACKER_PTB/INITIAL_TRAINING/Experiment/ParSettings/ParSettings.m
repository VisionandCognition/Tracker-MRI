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
Par.TR = 3; % Not important during training
Par.MRITriggeredStart = true;
Par.MRITrigger_OnlyOnce = true;

%% Get stimulus info ======================================================
eval(Par.STIMSETFILE);
Stm=StimObj.Stm;

StimObj.Stm.FixDotCol = [.3 .3 .3 ; .1 .1 .1]; %[RGB if not fixating; RGB fixating]

% overrule generic fixation window
Par.FixWinSize = [1.8 1.8]; % [W H] in deg

%% Eyetracking parameters =================================================
Par.SetZero = false; %initialize zero key to not pressed
Par.SCx = 1.17; %initial scale in control window
Par.SCy = 1.17;
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

Par.MousePress = 0; %0 left = 'normal', 1 middle = 'extend', 2 right = 'alt'
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
Par.RewSndPar = [44100 800 1];
% [FS(Hz) TonePitch(Hz) Amplitude]
% duration matches 'open duration'
Par.RewardFixFeedBack = true;

% Require hands in the box (reduces movement?)
% Needed for initiation of tracker since it's in the gui now
Par.RewNeedsHandInBox=false;
Par.StimNeedsHandInBox=false;
Par.FixNeedsHandInBox=false;
Par.HandOutDimsScreen = false;
Par.HandOutDimsScreen_perc = 0.9; %(0-1, fraction dimming)

Par.HandIsIn=false;

Par.ManualRewardTargetOnly = false; % only give manual reward during target presentation
% prevents me from mistiming the manual reward during training

Par.OneRewardPerTrial = false; % for training allow multiple rewards/target
Par.RewardType = 0; % 0=fixed reward, 1=progressive, 2=stimulus dependent
switch Par.RewardType
    case 0
        Par.RewardTime = 0.075;
    case 1
        % Alternatively use a progressive reward scheme based on the number of
        % preceding consecutive correct responses format as
        % rows stating: [nCorrectTrials RewardTime]
        Par.RewardTime = [...
            0   0.100;...
            5   0.150;...
            10  0.200;...
            15  0.250;...
            20  0.300];
    case 2
        Par.RewardTime = 0; %no reward
end

Par.RewardTimeManual = 0.075; % amount of reward when given manually


%% Create Eye-check windows based on stimulus positions ===================
for SetInitialWINs=1
    % The code below is preloaded and will be overwritten on stimulus basis
    % for every trial individually
    %example window types, should be replaced by your own control windows
    FIX = 0;  %this is the fixation window
    TALT = 1; %this is an alternative/erroneous target window
    TARG = 2; %this is the correct target window
    
    %Par.WIN = [xpos, ypos, pix width, pix height, window type]
    Par.WIN = [...
        0,  0, Par.PixPerDeg*Par.FixWdDeg, Par.PixPerDeg*Par.FixHtDeg, FIX; ...
        100, 100, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TARG; ...
        -300, 300, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TALT].';
    
    %when target and fixation windows change in position and dimension you will
    %have to call two functions. The first is to show their position on the tracker screen.
    %The second is to update das routines that detect eye movements entering
    %and leaving these windows
    % 1. ->refreshtracker( 1) %clear tracker screen and set fixation and target windows
    % 2. ->SetWindowDas %set das control thresholds using global parameters : Par
end

%% Trial count inital =====================================================
Par.Trlcount = [0 0]; %[this_position total]
Par.CorrStreakcount = [0 0];

%% Keyboard initialization ================================================
Par.KeyEscape = KbName('Escape'); % allows breaking out of the experiment
Par.KeyTriggerMR = KbName('t'); % MRI sends a sync pulse as a 't' keypress
Par.KeyJuice = KbName('j'); % Manual juice reward
Par.KeyBackNoise = KbName('b'); % toggle background noise patch
Par.KeyDistract = KbName('d'); % toggle distracter
Par.KeyCyclePos = KbName('p'); % toggle cycle position

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
     
%% Trial timing information ===============================================
Par.Times.ToFix = 2000; %time to enter fix window in ms
Par.Times.Fix = 0;  % Par.Times.Fix = 300;  %Time in fixation window
Par.Times.Stim = 50;  %Stimulus on time
Par.Times.Targ = 50;  %Time to keep fixating after stim onset
Par.Times.Rt = 500;  %Time to make eye movement
Par.Times.InterTrial = 0; %Par.Times.InterTrial = 1000; %intertrial time

Par.Times.RndFix = 0; %max uniform random time to add to stimulus onset time
Par.Times.RndStim = 0; %max uniform random time to add to stimulus display time
Par.Times.RndTarg = 0; %max uniform random time to add to target onset time

Par.Times.Sacc = 100; %max time to finish saccade
Par.Times.Err = 500; %time to add to in RT-epoch after error
% 
Par.Drum = false;     %drumming on or off, redoing error trials
Par.DrumType = 1; %1=immediately repeat, 2=append to end, 3=insert randomly
Par.isRunning = false;  %stimulus presentation off

%% Tracker window control =================================================
Par.ZOOM = 0.52;   %control - cogent window zoom
Par.P1 = 1;
Par.P2 = 1;

%% Logging ================================================================
Par.LogFolder = 'InitialTraining'; 