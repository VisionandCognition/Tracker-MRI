%Prestim
%Updated 20_05_2014 Chris van der Togt

global Par;
global LPStat;

BtOn = 0;  %if using button presses set to 1
Board = int32(22);  %mcc board = 22; Demo-board = 0 

 if ~isfield(Par, 'DasOn')
     Par.DasOn = 0; %persistent value
 end
 
if Par.DasOn ~= 1
 
    LPStat = dasinit( Board, 2);  %mexfunction acces!! give board number
    Par.DasOn = 1;                %and number of channels
end

%initialize  Cogent 
warning('off','MATLAB:dispatcher:InexactMatch')
cgloadlib
%cgopen(Res,BPP,RefRate,Monitor<,'Alpha'>) or
%cgopen(HPix,VPix,BPP,RefRate,Monitor<,’Alpha’>)

%cgopen(1,0,0,0) %cogent window(640x480x32)
cgopen(3,0,0,2)  %Display:1024x768x32 75.02Hz
%cogstd('spriority','high')
%we could also load sounds to give the monkey feedback
%[Sy,Fs,bits] = wavread('C:\Documents and Settings\All\Users\Documents\mfiles\COG\drip.wav');
   

%////////////////////global variable Par settings////////////////////////////////////////
Par.SetZero = false; %initialize zero key to not pressed
Par.SCx = 0.2; %initial scale in control window
Par.SCy = 0.2;
Par.OFFx = 0; %initial eye offset x => (center) of camera das output
Par.OFFy = 0; %initial eye offset y
%if using eyelink set to -1.0 else 1.0
Par.xdir = 1;
Par.ydir = 1;
Par.Sdx = 0; %2* standard error on eyechannels in pixels
Par.Sdy = 0;

Par.Trlcount = 0;
Par.Corrcount = 0;
Par.Errcount = 0;

Par.ZOOM = 1.0;   %control - cogent window zoom
Par.P1 = 1;
Par.P2 = 1;

Par.MousePress = 0; %0 left = 'normal', 1 middle = 'extend', 2 right = 'alt'


gsd = cggetdata('gsd'); 
Par.HW = gsd.PixOffsetX; %get half width of the screen
Par.HH = gsd.PixOffsetY;

Par.DistanceToScreen = 50; %cm
Par.ScreenWidthD2 = 18; %cm
Par.PixPerDeg = Par.HW/atand(18/50); 
Par.FixWdDeg = 1;
Par.FixHtDeg = 1;
Par.TargWdDeg = 2;
Par.TargHtDeg = 2;
Par.Bsqr = 0; %use square (1) or ellipse (0 )

Par.ErrorB = 0; 
Par.StimB = 1;
Par.TargetB = 2;
Par.RewardB = 3;
%Par.SaccadeB = 4; done by DasControl
%Par.TrialB = 5;   done by DasControl
Par.MicroB = 6;
Par.CorrectB = 7; 

Par.Reward = true; %boolean to enable reward stim bit or not 
Par.RewardTime = 0.150; %Reward time is set to 100ms

gpd = cggetdata('GPD');
%check if refresh rate is correct
T = zeros(100,1);
for i = 1:100
    T(i) = cgflip();
end
Rf = 1/ mean(diff(T(2:100)));
if round(gpd.RefRate100/1000) ~= round(Rf/10)  %should be approximately the same
    disp(['Warning!: refreshrate not properly reported by cogent; ' num2str(gpd.RefRate100/100) 'Hz'] ) 
    Par.fliptime = mean(diff(T(2:100)))*1000; %in ms
else
    Par.fliptime = 100000/gpd.RefRate100; %fliptime in ms
end

Par.Times.ToFix = 2000; %time to enter fix window in ms
Par.Times.Fix = 300;  %Time in fixation window
Par.Times.Stim = 50;  %Stimulus on time
Par.Times.Targ = 50;  %Time to keep fixating after stim onset
Par.Times.Rt = 500;  %Time to make eye movement
Par.Times.InterTrial = 1000; %intertrial time


Par.Times.RndFix = 0; %max uniform random time to add to stimulus onset time
Par.Times.RndStim = 0; %max uniform random time to add to stimulus display time
Par.Times.RndTarg = 0; %max uniform random time to add to target onset time
Par.Times.Sacc = 100; %max time to finish saccade
Par.Times.Err = 500; %time to add after error

Par.NoiseUpdate = false; %show standard error of noise in fixation period
Par.Drum = false;     %drumming on or off, redoing error trials
Par.BG = [0.0; 0.0; 0.0]; %default background Color
Par.NoiseUpdate = 0; %calculate noise level
Par.isRunning = false;  %stimulus presentation off
Par.RUNFUNC = 'runstim';

%example, should be replaced by your own control windows
FIX = 0;  %this is the fixation window
TALT = 1; %this is an alternative/erroneous target window
TARG = 2; %this is the correct target window

%Par.WIN    xpos, ypos,     pix width,              pix height,          window type
Par.WIN = [   0,  0, Par.PixPerDeg*Par.FixWdDeg, Par.PixPerDeg*Par.FixHtDeg, FIX; ...
           100, 100, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TARG; ...
           -300, 300, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, TALT].';

%when target and fixation windows change in position and dimension you will
%have to call two functions. The first is to show their position on the tracker screen. 
%The second is to update das routines that detect eye movements entering
%and leaving these windows 
% 1. ->refreshtracker( 1) %clear tracker screen and set fixation and target windows
% 2. ->SetWindowDas %set das control thresholds using global parameters : Par

%to use or not use the mouse
Par.Mouserun = 0;
Par.MOff(1) = 0;  %mouse offsets
Par.MOff(2) = 0;
