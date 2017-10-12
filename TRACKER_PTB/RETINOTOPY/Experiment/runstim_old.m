function runstim(Hnd)
% Updated February 2016, Chris Klink (c.klink@nin.knaw.nl)
% Fixation & diverse retinotopic mapping stimuli
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
    % Reduce PTB3 verbosity
    oldLevel = Screen('Preference', 'Verbosity', 0); %#ok<*NASGU>
    Screen('Preference', 'VisualDebuglevel', 0);
    Screen('Preference','SkipSyncTests',1);
    
    %Do some basic initializing
    AssertOpenGL;
    KbName('UnifyKeyNames');
    
    %Set ParFile and Stimfile
    Par.PARSETFILE = 'ParSettings_NoDas';
    Par.STIMSETFILE = 'StimSettings_pRF_8bars'; %'StimSettings_FullscreenCheckerboard';
    Par.MONKEY = 'TestWithoutDAS';
end
clc;

%% Prior To Dealing With Stimuli ==========================================
% set PTB priority to max
priorityLevel=MaxPriority(Par.window);
oldPriority=Priority(priorityLevel);

%% set up the manual response task
for define_square=1 % left / square
    lmost=-1/2;
    rmost= 1/2;
    tmost=-1/2;
    bmost= 1/2;
    left_square = [lmost,tmost; ...
          rmost,tmost; ...
          rmost,bmost; ...
          lmost,bmost ...
          ];
end
for define_diamond=1 % right / diamond
    lmost=-sqrt(2)*1/2;
    rmost= sqrt(2)*1/2;
    tmost=-sqrt(2)*1/2;
    bmost= sqrt(2)*1/2;
    right_diamond = [lmost,0; ...
          0,tmost; ...
          rmost,0; ...
          0,bmost ...
          ];
end
for define_circle=1 % shown when subject needs to release response
    lmost=-sqrt(1/pi);
    rmost= sqrt(1/pi);
    tmost=-sqrt(1/pi);
    bmost= sqrt(1/pi);
    blocked_circle = [lmost, tmost, rmost, bmost ...
          ];
end

%% initialize stuff
Par.ESC = false; %escape has not been pressed
GrandTotalReward=0;
LastRewardAdded=false;
CollectPerformance=[];
CloseTextures=false;

Par.RewardStartTime=0;
        
% re-run parameter-file to update stim-settings without restarting Tracker
eval(Par.PARSETFILE); % can be chosen in menu
Par.ScrCenter=Par.wrect(3:4)/2;
DateString = datestr(clock,30);
DateString = DateString(1:end-2);
Par_BU=Par;
if ~TestRunstimWithoutDAS
    refreshtracker(1);
end

% output stimsettings filename to cmd
fprintf(['Setup selected: ' Par.SetUp '\n']);
%fprintf(['Screen selected: ' Par.ScreenChoice '\n']);
fprintf(['TR: ' num2str(Par.TR) 's\n\n']);

fprintf(['=== Running ' Par.STIMSETFILE ' for ' Par.MONKEY ' ===\n']);
if ~strcmp(Par.ResponseBox.Task, 'DetectGoSignal')% do no show this if reward is based on task
    if numel(Par.Times.Targ)>1
        fprintf(['Progressive fix-to-reward times between ' num2str(Par.Times.Targ(1,2)) ...
            ' and ' num2str(Par.Times.Targ(end,2)) ' ms\n']);
    else
        fprintf(['Hold fixation for ' num2str(Par.Times.Targ) ' ms to get reward\n']);
    end
end
Par.RewardTime=Par.RewardTimeSet;
Stm = StimObj.Stm;
fprintf(['Started at ' DateString '\n']);

% overwrite the stimsettings fix-window with the one from parsettings
for sss=1:length(Stm)
    Stm(sss).FixWinSize = Par.FixWinSize;
    if ~TestRunstimWithoutDAS
        refreshtracker(1);
    end
end

% If multiple stimuli are defined, arrange order
Log.StimOrder=[];
for nR=1:Stm(1).nRepeatsStimSet
    if length(Stm)>1
        nSTIM=length(Stm);
        if Stm(1).RandomizeStim
            Log.StimOrder = [Log.StimOrder randperm(nSTIM)];
        else
            Log.StimOrder = [Log.StimOrder 1:nSTIM];
        end
        StimLoopNr=0;
    else
        Log.StimOrder = [Log.StimOrder 1];
        StimLoopNr=0;
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
% Load retinotopic mapping stimuli
FaceRingsLoaded=false; FaceWedgeLoaded=false;
WalkerRingsLoaded=false; WalkerWedgeLoaded=false;
for STIMNR = unique(Log.StimOrder);
    switch Stm(STIMNR).RetMap.StimType{1}
        case 'none'
            Stm(STIMNR).Descript = 'NoStim';
        case 'ret'
            %% Retinotopy stim
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'pRF_8bar')
                Stm(STIMNR).Order=1:Stm(STIMNR).RetMap.nSteps;
                Stm(STIMNR).Descript = 'pRF_8bar';
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge_cw')
                Stm(STIMNR).Order=Stm(STIMNR).RetMap.nSteps:-1:1;
                Stm(STIMNR).Descript = 'wedge_cw';
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge_ccw')
                Stm(STIMNR).Order=1:Stm(STIMNR).RetMap.nSteps;
                Stm(STIMNR).Descript = 'wedge_ccw';
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'ring_con')
                Stm(STIMNR).Order=Stm(STIMNR).RetMap.nSteps:-1:1;
                Stm(STIMNR).Descript = 'ring_con';
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'ring_exp')
                Stm(STIMNR).Order=1:Stm(STIMNR).RetMap.nSteps;
                Stm(STIMNR).Descript = 'ring_exp';
            end
            if Stm(STIMNR).RetMap.LoadFromFile
                fprintf(['\nLoading retinotopy stimulus: ' ...
                    Stm(STIMNR).RetMap.FileName '...\n']);
                cd Stimuli
                cd RetMap
                D=load(Stm(STIMNR).RetMap.FileName);
                stimulus=D.stimulus;fps=D.fps;
                cd ..
                cd ..
            else
                fprintf('Creating retinotopy stimulus...\n');
                stimulus = ck_ret(Stm,STIMNR);
                fps = Stm(STIMNR).RetMap.fps;
                if Stm(STIMNR).RetMap.SaveToFile
                    fprintf('\nSaving retinotopy stimulus...\n');
                    cd Stimuli
                    cd RetMap
                    save(Stm(STIMNR).RetMap.FileName,'stimulus','fps','Stm','-v7.3');
                    cd ..
                    cd ..
                end
            end
            %% img to textures
            pos=0; %Stm(STIMNR).RetMap.posmap = [];
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'pRF_8bar')
                for rv=1:length(stimulus(1).orient); %length(stimulus) % directions
                    for ii=1:length(stimulus(1).img) % positions
                        pos=pos+1;
                        for jj = 1:size(stimulus(1).img{ii},3) % frame
                            if rv==1
                                img1 = stimulus(1).img{ii}(:,:,jj);
                                ret_vid(pos).img{jj} = img1;  %#ok<*AGROW>
                                ret_vid(pos).text(jj) = Screen('MakeTexture', ...
                                    Par.window,img1);
                            end
                            ret_vid(pos).fps = fps;
                            ret_vid(pos).orient(jj) = stimulus(1).orient(rv);
                        end
                    end
                end
            else
                for rv=1:length(stimulus)
                    for ii=1:length(stimulus(rv).img) % positions
                        pos=pos+1;
                        for jj = 1:size(stimulus(rv).img{ii},3) % frame
                            ret_vid(pos).img{jj} = stimulus(rv).img{ii}(:,:,jj);  %#ok<*AGROW>
                            ret_vid(pos).fps = fps;
                            ret_vid(pos).text(jj) = Screen('MakeTexture', Par.window, ...
                                ret_vid(pos).img{jj});
                        end
                    end
                end
            end
            CloseTextures = true;
            Stm(STIMNR).RetMap.posmap = stimulus(1).posmap;
        case 'face'
            %% Classic retinotopy: faces
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle')
                if Stm(STIMNR).RetMap.Dir == 1 %expanding
                    Stm(STIMNR).Order=1:32;
                    Stm(STIMNR).Descript = 'FaceRingExp';
                elseif Stm(STIMNR).RetMap.Dir == -1 %contracting
                    Stm(STIMNR).Order=32:-1:1;
                    Stm(STIMNR).Descript = 'FaceRingCon';
                end
                if ~FaceRingsLoaded
                    cd Stimuli
                    cd faces
                    fprintf('Loading faces01_rings.mat\n');
                    vid_face_ring = load('faces01_rings.mat'); % loads 'ret_vid' structure
                    FaceRingsLoaded=true;
                    cd ..
                    cd ..
                    face_ring_vidtex_made=false;
                end
            elseif  strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge')
                if Stm(STIMNR).RetMap.Dir == 1 %ccw
                    Stm(STIMNR).Order=1:32;
                    Stm(STIMNR).Descript = 'FaceWedgeCCW';
                elseif Stm(STIMNR).RetMap.Dir == -1 %cw
                    Stm(STIMNR).Order=[1 32:-1:2];
                    Stm(STIMNR).Descript = 'FaceWedgeCW';
                end
                if ~FaceWedgeLoaded
                    cd Stimuli
                    cd faces
                    fprintf('Loading faces01_wedge.mat\n');
                    vid_face_wedge = load('faces01_wedge.mat'); % loads 'ret_vid' structure
                    FaceWedgeLoaded=true;
                    cd ..
                    cd ..
                    face_wedge_vidtex_made=false;
                end
            end
            Stm(STIMNR).RetMap.posmap = [(1:32)' Stm(STIMNR).Order'];
            % img to textures
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle') && ~face_ring_vidtex_made
                fprintf('Creating stimulus textures\n');
                for rv=1:length(vid_face_ring.ret_vid)
                    for ii=1:length(vid_face_ring.ret_vid(rv).img)
                        vid_face_ring.ret_vid(rv).text(ii) = Screen('MakeTexture', Par.window, ...
                            vid_face_ring.ret_vid(rv).img{ii});
                    end
                end
                face_ring_vidtex_made=true;
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge') && ~face_wedge_vidtex_made
                fprintf('Creating stimulus textures\n');
                for rv=1:length(vid_face_wedge.ret_vid)
                    for ii=1:length(vid_face_wedge.ret_vid(rv).img)
                        vid_face_wedge.ret_vid(rv).text(ii) = Screen('MakeTexture', Par.window, ...
                            vid_face_wedge.ret_vid(rv).img{ii});
                    end
                end
                face_wedge_vidtex_made=true;
            end
            CloseTextures = true;
        case 'walker'
            %% Classic retinotopy: walkers
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle')
                if Stm(STIMNR).RetMap.Dir == 1 %expanding
                    Stm(STIMNR).Order=1:32;
                    Stm(STIMNR).Descript = 'WalkerRingExp';
                elseif Stm(STIMNR).RetMap.Dir == -1 %contracting
                    Stm(STIMNR).Order=32:-1:1;
                    Stm(STIMNR).Descript = 'WalkerRingCon';
                end
                if ~WalkerRingsLoaded
                    cd Stimuli
                    cd walkers
                    fprintf('Loading walker01_rings.mat\n');
                    vid_walker_ring = load('walker01_rings.mat'); % loads ret_vid structure
                    WalkerRingsLoaded=true;
                    cd ..
                    cd ..
                    walker_ring_vidtex_made=false;
                end
            elseif  strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge')
                if Stm(STIMNR).RetMap.Dir == 1 %ccw
                    Stm(STIMNR).Order=1:32;
                    Stm(STIMNR).Descript = 'WalkerWedgeCCW';
                elseif Stm(STIMNR).RetMap.Dir == -1 %cw
                    Stm(STIMNR).Order=[1 32:-1:2];
                    Stm(STIMNR).Descript = 'WalkerWedgeCW';
                end
                if ~WalkerWedgeLoaded
                    cd Stimuli
                    cd walkers
                    fprintf('Loading walker01_wedge.mat\n');
                    vid_walker_wedge = load('walker01_wedge.mat'); % loads ret_vid structure
                    WalkerWedgeLoaded=true;
                    cd ..
                    cd ..
                    walker_wedge_vidtex_made=false;
                end
            end
            Stm(STIMNR).RetMap.posmap = [(1:32)' Stm(STIMNR).Order'];
            % img to textures
            if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle') && ~walker_ring_vidtex_made
                fprintf('Creating stimulus textures\n');
                for rv=1:length(vid_walker_ring.ret_vid)
                    for ii=1:length(vid_walker_ring.ret_vid(rv).img)
                        vid_walker_ring.ret_vid(rv).text(ii) = Screen('MakeTexture', Par.window, ...
                            vid_walker_ring.ret_vid(rv).img{ii});
                    end
                end
                walker_ring_vidtex_made=true;
            elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge') && ~walker_wedge_vidtex_made
                fprintf('Creating stimulus textures\n');
                for rv=1:length(vid_walker_wedge.ret_vid)
                    for ii=1:length(vid_walker_wedge.ret_vid(rv).img)
                        vid_walker_wedge.ret_vid(rv).text(ii) = Screen('MakeTexture', Par.window, ...
                            vid_walker_wedge.ret_vid(rv).img{ii});
                    end
                end
                walker_wedge_vidtex_made=true;
            end
            CloseTextures = true;
        case 'checkerboard'
            %% fullscreen checkerboard
            Stm(STIMNR).Descript = 'FullChecker';
    end
end

TotTime=0;
for i=1:length(Stm)
    if strcmp(Stm(i).RetMap.StimType{1},'checkerboard')
        Stm(i).RetMap.PreDur = ...
            Stm(i).RetMap.PreDur_TRs*Par.TR;
        Stm(i).RetMap.PostDur = ...
            Stm(i).RetMap.PostDur_TRs*Par.TR;
        Stm(i).RetMap.Checker.OnOff = ...
            Stm(i).RetMap.Checker.OnOff_TRs*Par.TR;
        TotTime = TotTime + ...
            (sum(Stm(i).RetMap.Checker.OnOff)*Stm(i).RetMap.nCycles)+...
            Stm(i).RetMap.PreDur+Stm(i).RetMap.PostDur;
    else
        Stm(i).RetMap.PreDur = ...
            Stm(i).RetMap.PreDur_TRs*Par.TR;
        Stm(i).RetMap.PostDur = ...
            Stm(i).RetMap.PostDur_TRs*Par.TR;
        if strcmp(Stm(i).RetMap.StimType{1},'ret')
            if Stm(i).RetMap.nCycles
                TotTime = TotTime + ...
                    Stm(i).RetMap.nCycles*...
                    size(Stm(i).RetMap.posmap,1)*...
                    Stm(i).RetMap.TRsPerStep*Par.TR + ...
                    Stm(i).RetMap.PreDur + Stm(i).RetMap.PostDur;
            else % no endpoint defined
                TotTime = Inf;
            end
        else
            if Stm(i).RetMap.nCycles
                TotTime = TotTime + ...
                    Stm(i).nRepeatsStimSet*Stm(i).RetMap.nCycles*...
                    Stm(i).RetMap.nSteps *...
                    Stm(i).RetMap.TRsPerStep*Par.TR + ...
                    Stm(i).RetMap.PreDur + Stm(i).RetMap.PostDur;
            else % no endpoint defined
                TotTime = Inf;
            end
        end
    end
end
if ~isinf(TotTime)
    NumVolNeeded=(Stm(1).nRepeatsStimSet*TotTime)/Par.TR;
    fprintf(['This StimSettings file requires at least ' num2str(NumVolNeeded) ...
        ' scanvolumes (check scanner)\n']);
else
    fprintf('NB: No end-time defined. This will keep running until stopped.\n')
end

%% Run this loop all stimuli the StimSettings file ========================
Par.ESC=false; Log.TotalTimeOut = 0; Par.Pause = false;
update_trackerfix_now = true;
for STIMNR = Log.StimOrder;
    %% Cycles of stimuli
    nCyclesDone=0;
    nCyclesReported=0;
    Log.TimeOutThisRun=0;
    Stm(STIMNR).IsPostDur=false;
    if ~Par.ESC
        StimLoopNr=StimLoopNr+1;
        Log.RunNr=StimLoopNr;
        %% Stimulus preparation -------------------------------------------
        % Fixation
        if StimLoopNr == 1 % only defining the fix window on first loop allows setting it via gui
            Stm(STIMNR).FixWinSizePix = round(Stm(STIMNR).FixWinSize*Par.PixPerDeg);
        end
        Stm(STIMNR).FixDotSizePix = round(Stm(STIMNR).FixDotSize*Par.PixPerDeg);
        Par.RespIndSizePix = round(Par.RespIndSize*Par.PixPerDeg);
        Stm(STIMNR).FixDotSurrSizePix = round(Stm(STIMNR).FixDotSurrSize*Par.PixPerDeg);
        Par.GoBarSizePix = round(Par.GoBarSize*Par.PixPerDeg);
        Stm(STIMNR).Center =[];
        for i=1:size(Stm(STIMNR).Position,2);
            Stm(STIMNR).Center =[Stm(STIMNR).Center; ...
                round(Stm(STIMNR).Position{i}.*Par.PixPerDeg)];
        end
        
        % Load retinotopic mapping stimuli
        switch Stm(STIMNR).RetMap.StimType{1}
            case 'none'
                %% only fixation
                RetMapStimuli=false;
                DispChecker=false;
            case 'ret'
                %% Population receptive field stim
                RetMapStimuli=true;
                DispChecker=false;
            case 'face'
                %% Classic retinotopy: faces
                RetMapStimuli=true;
                DispChecker=false;
                if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle')
                    ret_vid=vid_face_ring.ret_vid;
                elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge')
                    ret_vid=vid_face_wedge.ret_vid;
                end
            case 'walker'
                %% Classic retinotopy: walkers
                RetMapStimuli=true;
                DispChecker=false;
                if strcmp(Stm(STIMNR).RetMap.StimType{2},'circle')
                    ret_vid=vid_walker_ring.ret_vid;
                elseif strcmp(Stm(STIMNR).RetMap.StimType{2},'wedge')
                    ret_vid=vid_walker_wedge.ret_vid;
                end
            case 'checkerboard'
                %% fullscreen checkerboard
                fn_lead='fullchecker_';
                Stm(STIMNR).Descript = 'FullChecker';
                RetMapStimuli=false;
                DispChecker=true;
                if Stm(STIMNR).RetMap.Checker.LoadFromFile;
                    fprintf(['\nLoading checkerboard ' ...
                        Stm(STIMNR).RetMap.Checker.FileName '...\n']);
                    cd Stimuli
                    cd fullchecker
                    load(Stm(STIMNR).RetMap.Checker.FileName);
                    cd ..
                    cd ..
                else
                    fprintf('\nCreating checkerboard...\n');
                    % create the checkerboard
                    chksize = ceil(Stm(STIMNR).RetMap.Checker.Size*Par.PixPerDeg);
                    chkimg = double(RadialCheckerBoard(...
                        [chksize ...
                        ceil(Stm(STIMNR).RetMap.Checker.centerradius*Par.PixPerDeg)], ...
                        Stm(STIMNR).RetMap.Checker.Sector, ...
                        Stm(STIMNR).RetMap.Checker.chsz));
                    if Stm(STIMNR).RetMap.Checker.SaveToFile
                        fprintf('\nSaving checkerboard...\n');
                        cd Stimuli
                        cd fullchecker
                        save(Stm(STIMNR).RetMap.Checker.FileName,'chkimg');
                        cd ..
                        cd ..
                    end
                end
                % create texture
                CB1R = chkimg(:,:,1)./Par.ScrWhite;
                CB1R(chkimg(:,:,1)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,1);
                CB1R(chkimg(:,:,1)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,1);
                CB1G=chkimg(:,:,1)./Par.ScrWhite;
                CB1G(chkimg(:,:,1)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,2);
                CB1G(chkimg(:,:,1)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,2);
                CB1B=chkimg(:,:,1)./Par.ScrWhite;
                CB1B(chkimg(:,:,1)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,3);
                CB1B(chkimg(:,:,1)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,3);
                CB1A = chkimg(:,:,3);
                CB1 = CB1R.*Par.ScrWhite;
                CB1(:,:,2)=CB1G.*Par.ScrWhite;
                CB1(:,:,3)=CB1B.*Par.ScrWhite;
                %CB1(:,:,4)=CB1A;
                CB1(:,:,4)=CB1A *1; % Make more transparent
                
                CB2R = chkimg(:,:,2)./Par.ScrWhite;
                CB2R(chkimg(:,:,2)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,1);
                CB2R(chkimg(:,:,2)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,1);
                CB2G=chkimg(:,:,2)./Par.ScrWhite;
                CB2G(chkimg(:,:,2)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,2);
                CB2G(chkimg(:,:,2)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,2);
                CB2B=chkimg(:,:,2)./Par.ScrWhite;
                CB2B(chkimg(:,:,2)==Par.ScrWhite) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(1,3);
                CB2B(chkimg(:,:,2)==0) = ...
                    Stm(STIMNR).RetMap.Checker.Colors(2,3);
                CB2A = chkimg(:,:,3);
                CB2 = CB2R.*Par.ScrWhite;
                CB2(:,:,2)=CB2G.*Par.ScrWhite;
                CB2(:,:,3)=CB2B.*Par.ScrWhite;
                %CB2(:,:,4)=CB2A;
                CB2(:,:,4)=CB2A *1; % Make more transparent
                
                CheckTexture(1)=Screen('MakeTexture', Par.window, CB1);
                CheckTexture(2)=Screen('MakeTexture', Par.window, CB2);
                TrackingCheckerContChange = false;
        end
        
        fprintf(['\nRun: ' num2str(Log.RunNr)]);
        fprintf(['\n-- Stimulus: ' Stm(STIMNR).Descript ' --\n']);
        
        %% Code Control Preparation ---------------------------------------
        Par.FixStatToCMD=true;
        
        % Some intitialization of control parameters
        if Par.MRITrigger_OnlyOnce && StimLoopNr == 1;
            Log.MRI.TriggerReceived = false;
        elseif ~Par.MRITrigger_OnlyOnce
            Log.MRI.TriggerReceived = false;
        end
        
        Log.MRI.TriggerTime = [];
        Log.ManualReward = false;
        Log.ManualRewardTime = [];
        Log.TotalReward=0;
        
        % Initial stimulus position is 1
        Par.PosNr=1;
        Par.PrevPosNr=1;
        
        % Initialize the side of response
        Par.ResponseSide=0;
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
        Par.BeamIsBlocked=false(size(Par.ConnectBox.PhotoAmp_used));
        
        %video control
        Par.VideoLoaded=false;
        Par.VideoPlaying=false;
        Par.VidNumber=1;
        Par.nVidStarted=0;
        Par.VidFrameTime=-1;
        Par.LastVidFrameTime=-1;
        Par.VidFrameNr=1;
        Par.VidCycleNr=1;
        Par.VidTexMade=false;
        Par.VideoAppend=false;
        LogFirstVidStartTime=false;
        FirstVidDrawn=false;
        
        % keep track of timing
        Log.lfts=[];
        
        %Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite); % black first
        % Flip the proper background on screen
        %Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
        
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
        
        %% Stimulus presentation loop =====================================
        
        %% Eye-tracker recording
        if Par.EyeRecAutoTrigger
            if ~FirstEyeRecSet
                SetEyeRecStatus(0); % send record off signal
                hmb=msgbox('Prepare the eye-tracker for recording','Eye-tracking');
                uiwait(hmb);
                FirstEyeRecSet=true;
                pause(1);
            end
            
            MoveOn=false;
            StartSignalSent=false;
            while ~MoveOn
                StartEyeRecCheck = GetSecs;
                while ~Par.EyeRecStatus && GetSecs < StartEyeRecCheck + 3 % check for 3 seconds
                    CheckEyeRecStatus; % checks the current status of eye-recording
                    if ~StartSignalSent
                        SetEyeRecStatus(1);
                        StartSignalSent=true;
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
        end
        
        %% MRI triggered start
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
    end
    
    %% Displaying the stimuli
    while ~Par.ESC && ~RunEnded
        while ~Par.FirstInitDone        
            %set control window positions and dimensions
            if ~TestRunstimWithoutDAS
                DefineEyeWin(STIMNR);
                refreshtracker(1) %for your control display
                last_tracker_update = GetSecs;
                SetWindowDas      %for the dascard, initializes eye control windows
            end
            
            Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
            Par.ResponseGiven=false;
            Par.FalseResponseGiven=false;
            Par.RespValid = false;
            Par.CorrectThisTrial=false;
            Par.LastFixInTime=0;
            Par.LastFixOutTime=0;
            Par.FixIn=false; %initially set to 'not fixating'
            Par.CurrFixCol=Stm(STIMNR).FixDotCol(1,:).*Par.ScrWhite;
            Par.FixInOutTime=[0 0];
            Par.FirstStimDrawDone=false;
            
            if StimLoopNr == 1 % allow time-outs to across runs
                Par.Pause=false;
            end
            if Par.Pause
                Screen('FillRect',Par.window,[0 0 0]);
                lft=Screen('Flip', Par.window);   %initial flip to sync up timing
            else
                lft=Screen('Flip', Par.window);  %initial flip to sync up timing
            end
            nf=0;
            Log.StartBlock=lft;
            Stm(STIMNR).IsPreDur=true;
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type='PreDurStart';
            Log.Events(Log.nEvents).t=Log.StartBlock-Par.ExpStart;
            Log.Events(Log.nEvents).StimName = [];
            if TestRunstimWithoutDAS; Hit=0; end
            
            Par.FirstInitDone=true;
            
            PreStarted = false;
            OnStarted = false;
            OffStarted = false;
            PostStarted = false;
            
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
        end
        %% Check what to draw depending on time
        if RetMapStimuli
            if GetSecs < Log.StartBlock + Stm(STIMNR).RetMap.PreDur % PreDur
                IsPre=true;
                IsPost=false;
                if ~PreStarted
                    PreStarted = true;
                    CheckStartLogged = false;
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='PreDurStart';
                    Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = [];
                    posn=0;
                end
            elseif GetSecs >= Log.StartBlock + Stm(STIMNR).RetMap.PreDur && ...
                    GetSecs < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    (Stm(STIMNR).RetMap.nCycles*size(Stm(STIMNR).RetMap.posmap,1)*...
                    Stm(STIMNR).RetMap.TRsPerStep*Par.TR) % in stimulus cycle
                IsPre=false;
                IsPost=false;
                if ~OnStarted
                    OnStarted=true;
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='StimON';
                    Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
                end
                
                TRn=ceil((GetSecs-Log.StartBlock-Stm(STIMNR).RetMap.PreDur)/Par.TR);
                prevposn=posn;
                posn = ceil(TRn/Stm(STIMNR).RetMap.TRsPerStep);
                
                while posn>size(Stm(STIMNR).RetMap.posmap,1);
                    posn=posn-size(Stm(STIMNR).RetMap.posmap,1);
                end
                posn=Stm(STIMNR).RetMap.posmap(posn,2);
                if posn ~= prevposn
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='NewPosition';
                    Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = posn;
                end
                
                if strcmp(Stm(STIMNR).RetMap.StimType{1},'ret') && posn
                    posn_adj = mod(posn-1,length(stimulus(1).img))+1;
                    texn = ceil(mod(GetSecs-Log.StartBlock,Par.TR)*...
                        ret_vid(posn_adj).fps); 
                    if ~texn; texn=1; end;
                    while texn>numel(ret_vid(posn_adj).text);
                        texn=texn-numel(ret_vid(posn_adj).text);
                    end
                elseif posn
%                     posn_adj = mod(posn-1,length(stimulus(1).img))+1;
%                     texn = ceil(mod(GetSecs-Log.StartBlock,Par.TR)*...
%                         ret_vid(Stm(STIMNR).Order(posn_adj)).fps);
%                     if ~texn; texn=1; end;
%                     while texn>numel(ret_vid(Stm(STIMNR).Order(posn_adj)).text);
%                         texn=texn-numel(ret_vid(Stm(STIMNR).Order(posn_adj)).text);
%                     end
                    texn = ceil(mod(GetSecs-Log.StartBlock,Par.TR)*...
                        ret_vid(Stm(STIMNR).Order(posn)).fps);
                    if ~texn; texn=1; end;
                    while texn>numel(ret_vid(Stm(STIMNR).Order(posn)).text);
                        texn=texn-numel(ret_vid(Stm(STIMNR).Order(posn)).text);
                    end
                end

            elseif GetSecs < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    (Stm(STIMNR).RetMap.nCycles*size(Stm(STIMNR).RetMap.posmap,1)*...
                    Stm(STIMNR).RetMap.TRsPerStep*Par.TR) + ...
                    Stm(STIMNR).RetMap.PostDur % PostDur
                IsPre=false;
                IsPost = true;
                if ~PostStarted
                    PostStarted=true;
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='PostDurStart';
                    Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = [];
                    tPostStarted=GetSecs;
                end
            else 
                RunEnded=true;
                IsPre=false;
                IsPost=false;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='RunStop';
                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
            end
            DrawChecker=false;
        elseif DispChecker % coarse checkerboard
            %% fullscreen checkerboard
            if lft < Log.StartBlock+Stm(STIMNR).RetMap.PreDur
                IsPre = true;
                IsOn = false;
                IsOff = false;
                IsPost = false;
                if ~PreStarted
                    PreStarted = true;
                    CheckStartLogged = false;
                    Log.CheckerON=[];
                    Log.CheckerOFF=[];
                    CheckStartLogged=false;
                    CheckStopLogged=false;
                    ChkNum = 1;
                end
                WasPreDur=true;
                DrawChecker = false;
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur,...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles
                IsPre = false;
                IsOn = true;
                IsOff = false;
                IsPost = false;
                if ~OnStarted
                    OnStarted=true;
                    OffStarted=false;
                    Log.CheckerON = [Log.CheckerON; lft];
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='StimON';
                    Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
                    CheckStartLogged = true;
                    CheckStopLogged =false;
                end
                if WasPreDur % coming out of predur
                    Par.FixInOutTime=[Par.FixInOutTime;0 0];
                    WasPreDur=false;
                end
                if nCyclesDone < Stm(STIMNR).RetMap.nCycles || ...
                        ~Stm(STIMNR).RetMap.nCycles
                    DrawChecker = true;
                    if nCyclesDone > 0 && nCyclesReported < nCyclesDone
                        %output fixation statistics
                        if Par.FixStatToCMD
                            fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
                                sprintf('%0.1f',...
                                100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
                                '%%, Run: ' ...
                                sprintf('%0.1f',...
                                100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
                                '%%\n']);
                            Par.FixInOutTime = [Par.FixInOutTime;0 0];
                            nCyclesReported=nCyclesReported+1;
                        end
                    end
                end
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur-Stm(STIMNR).RetMap.Checker.OnOff(1),...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles
                IsPre = false;
                IsOn = false;
                IsOff = true;
                IsPost = false;
                if ~OffStarted
                    OffStarted=true;
                    OnStarted=false;
                    Log.CheckerOFF = [Log.CheckerOFF; lft];
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='StimOFF';
                    Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
                    nCyclesDone=nCyclesDone+1;
                    CheckStartLogged = false;
                    CheckStopLogged =true;
                end
                DrawChecker = false;
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur,...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft >= Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles && ...
                    ~PostStarted
                IsPre = false;
                IsOn = false;
                IsOff = false;
                IsPost = true;
                if ~PostStarted
                    PostStarted=true;
                    Log.StartPostDur=lft;
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='PostDurStart';
                    Log.Events(Log.nEvents).t=Log.StartPostDur-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = [];
                    DrawChecker = false;
                    if nCyclesDone > 0 && nCyclesReported < nCyclesDone
                        %output fixation statistics
                        if Par.FixStatToCMD
                            fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
                                sprintf('%0.1f',...
                                100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
                                '%%, Run: ' ...
                                sprintf('%0.1f',...
                                100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
                                '%%\n']);
                            Par.FixInOutTime = [Par.FixInOutTime;0 0];
                            nCyclesReported=nCyclesReported+1;
                        end
                    end
                end
            elseif lft >= Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles + ...
                    Stm(STIMNR).RetMap.PostDur
                RunEnded = true;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='RunStop';
                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
            end
        else
            DrawChecker = false;
        end
        
        prevlft=lft;
        FixTimeThisFlip = 0; NonFixTimeThisFlip = 0;
        Par.LastFlipFix = Par.FixIn;
        
        %% Check if eye enters fixation window
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
        
        %% Check eye position
        %Hit=0;
        if ~TestRunstimWithoutDAS
            dasrun(5); % takes max 5 ms
            [Hit, Time] = DasCheck;
            %Hit = LPStat(1);   %Hit yes or no
            %Time = LPStat(0);  %time
        end
        
        %% interpret
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
        
        %% Do this routine for all remaining flip time
        DoneOnce=false;
        while ~DoneOnce || GetSecs < prevlft+0.80*Par.fliptimeSec
            DoneOnce=true;
            
            %% check for key-presses
            CheckKeys; % internal function
            
            %% Change stimulus if required
            ChangeStimulus(STIMNR);
            
            %% give manual reward
            if Par.ManualReward && ~TestRunstimWithoutDAS
                GiveRewardManual;
                Par.ManualReward=false;
            end
            
            %% check photosensor
            if ~TestRunstimWithoutDAS
                CheckManual;
                if ~strcmp(Par.ResponseBox.Task,'DetectGoSignal') && ...
                        Par.StimNeedsHandInBox && ~Par.HandIsIn
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
            
            %% Stop reward
            StopRewardIfNeeded();
        end
        
        %% Draw stimulus
        if ~Par.Pause
            if RetMapStimuli
                DrawStimuli;
                if ~IsPre && ~IsPost && ~RunEnded && ~Par.ToggleHideStim ...
                        && ~Par.HideStim_BasedOnBeam(Par.BeamIsBlocked) ...
                        && ~Par.Pause
                    if strcmp(Stm(STIMNR).RetMap.StimType{1},'ret')
                        posn_adj = (mod(posn-1,length(stimulus(1).img))+1);
                        orinum = ceil(posn/length(stimulus(1).img));
                        if posn
                            if strcmp(Stm(STIMNR).RetMap.StimType{2},'pRF_8bar')
                                Screen('DrawTexture',Par.window,ret_vid(posn_adj).text(texn),...
                                    [],[],ret_vid(posn).orient(orinum),1);
                            else
                                Screen('DrawTexture',Par.window,ret_vid(posn).text(texn),...
                                    [],[],[],1);
                            end
                        end
                    else
                        if posn
                            Screen('DrawTexture',Par.window,ret_vid(posn).text(texn),...
                                [],[Par.ScrCenter(1)-Par.wrect(4)/2 0 ...
                                Par.ScrCenter(1)+Par.wrect(4)/2 Par.wrect(4)],...
                                [],1);
                        end
                    end
                end
            elseif DrawChecker
                DrawStimuli;
                if ~Par.HideStim_BasedOnBeam(Par.BeamIsBlocked) && ~Par.Pause
                    Screen('DrawTexture',Par.window,CheckTexture(ChkNum),[],...
                        [],[],1);
                end
            else
                DrawStimuli;
            end
        end
        
        %% Draw fixation dot
        if ~Par.ToggleHideFix ...
                && ~Par.HideFix_BasedOnBeam(Par.BeamIsBlocked) ...
                && ~Par.Pause
            DrawFix(STIMNR);
            DrawGoBar(STIMNR);
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
        
        %% darken the screen if on time-out
        if Par.Pause
            Screen('FillRect',Par.window,[0 0 0]);
        end
        
        %% dim the screen if requested due to hand position
        AutoDim; % checks by itself if it's required
        
        %% Calculate proportion fixation for this flip-time and label it
        % fix or no-fix
        if Par.FixIn
            if Par.RewardFixFeedBack
                Par.CurrFixCol=Stm(STIMNR).FixDotCol(2,:).*Par.ScrWhite;
            end
            
            Par.Trlcount=Par.Trlcount+1;
            %refreshtracker(3);
            if GetSecs >= Par.LastFixInTime+Par.Times.TargCurrent/1000 % fixated long enough
                % start Reward
                if ~Par.RewardRunning && ~TestRunstimWithoutDAS && ~Par.Pause && ...
                        ( (Par.RewNeedsHandInBox && Par.HandIsIn) || ~Par.RewNeedsHandInBox)
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
            Par.CurrFixCol=Stm(STIMNR).FixDotCol(1,:).*Par.ScrWhite;
            Par.CorrStreakcount=[0 0];
            %refreshtracker(1);
        end
        
        %% Stop reward
        StopRewardIfNeeded();
        
        %% if doing Par.ResponseBox.Task of 'DetectGoSignal':
        if strcmp(Par.ResponseBox.Task, 'DetectGoSignal') && ~TestRunstimWithoutDAS
            if Par.ResponseState == Par.RESP_STATE_DONE && Par.CanStartTrial(Par)
                UpdateHandTaskState(Par.RESP_STATE_WAIT);
                %Par.ResponseState = Par.RESP_STATE_WAIT;
                %Par.ResponseStateChangeTime = GetSecs;
                if Par.ResponseSide == 0
                    Par.ResponseSide = randi([1 2]);
                end
                Log.Events(Log.nEvents).StimName = num2str(Par.ResponseSide);
                Par.GoBarOnset = rand(1)*Par.EventPeriods(2)/1000 + ...
                    Par.EventPeriods(1)/1000;
                
                % Give side indicator (1 or 2) ... again
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type=strcat(...
                    'HandTask-TargetSide', num2str(Par.ResponseSide));
                Log.Events(Log.nEvents).t=Par.ResponseStateChangeTime;
                
            elseif Par.ResponseState == Par.RESP_STATE_WAIT
                if GetSecs >= Par.ResponseStateChangeTime + Par.GoBarOnset
                    UpdateHandTaskState(Par.RESP_STATE_GO);
                    %Par.ResponseState = Par.RESP_STATE_GO;
                    %Par.ResponseStateChangeTime = GetSecs;
                end
            elseif Par.ResponseState == Par.RESP_STATE_GO
                t = GetSecs;
                if Par.IncorrectResponseGiven(Par)
                    UpdateHandTaskState(Par.RESP_STATE_DONE);
                    Log.Events(Log.nEvents).StimName = 'Incorrect';
                    
                    % RESP_NONE =  0; RESP_CORRECT = 1;
                    % RESP_FALSE = 2; RESP_MISS = 3;
                    % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                    Par.ManResponse(RESP_FALSE) = Par.ManResponse(RESP_FALSE)+1;
                    
                elseif (Par.CorrectResponseGiven(Par) && ...
                         t < Par.ResponseStateChangeTime + Par.ResponseAllowed(1)/1000)
                    UpdateHandTaskState(Par.RESP_STATE_DONE);
                    Log.Events(Log.nEvents).StimName = 'Early';
                
                    %Par.ResponseState = Par.RESP_STATE_DONE;
                    %Par.ResponseStateChangeTime = GetSecs;
                    %Par.ResponseSide = 0;
                    
                    % RESP_NONE =  0; RESP_CORRECT = 1;
                    % RESP_FALSE = 2; RESP_MISS = 3;
                    % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                    Par.ManResponse(RESP_EARLY) = Par.ManResponse(RESP_EARLY)+1;
                    
                elseif Par.CorrectResponseGiven(Par) && ...
                        t >= Par.ResponseStateChangeTime + Par.ResponseAllowed(1)/1000
                    %Par.ResponseStateChangeTime = GetSecs;
                    %Par.ResponseState = Par.RESP_STATE_DONE;
                    UpdateHandTaskState(Par.RESP_STATE_DONE);
                    Log.Events(Log.nEvents).StimName = 'Hit';
                    GiveRewardAutoTask;
                    Par.ResponseSide = 0;
                    
                    % RESP_NONE =  0; RESP_CORRECT = 1;
                    % RESP_FALSE = 2; RESP_MISS = 3;
                    % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                    Par.ManResponse(RESP_CORRECT) = Par.ManResponse(RESP_CORRECT)+1;
                    
                elseif t >=  Par.ResponseStateChangeTime + Par.ResponseAllowed(2)/1000
                    UpdateHandTaskState(Par.RESP_STATE_DONE);
                    Log.Events(Log.nEvents).StimName = 'Miss';
                    %Par.ResponseState = Par.RESP_STATE_DONE;
                    %Par.ResponseStateChangeTime = GetSecs;
                    %Par.ResponseSide = 0;
                    
                    % RESP_NONE =  0; RESP_CORRECT = 1;
                    % RESP_FALSE = 2; RESP_MISS = 3;
                    % RESP_EARLY = 4; RESP_BREAK_FIX = 5;
                    Par.ManResponse(RESP_MISS) = Par.ManResponse(RESP_MISS)+1;
                    
                end
            end
        end
        
        %% refresh the screen
        %lft=Screen('Flip', Par.window, prevlft+0.9*Par.fliptimeSec);         
        lft=Screen('Flip', Par.window); % as fast as possible
        nf=nf+1;

        %% log eye-info if required
        LogEyeInfo;
        
        %% change the checkerboard contrast if required
        if DrawChecker
            if TrackingCheckerContChange
                if lft-tLastCheckerContChange >= ...
                        1/Stm(1).RetMap.Checker.FlickFreq_Approx;
                    if ChkNum==1;
                        ChkNum=2;
                    elseif ChkNum==2
                        ChkNum=1;
                    end
                    tLastCheckerContChange=lft;
                end
            else
                tLastCheckerContChange=lft;
                TrackingCheckerContChange=true;
            end
        end
        
        %% Switch position if required to do this automatically
        if Par.ToggleCyclePos && Stm(STIMNR).CyclePosition && ...
                Par.Trlcount(1) >= Stm(STIMNR).CyclePosition
            % next position
            Par.SwitchPos = true;
            Par.WhichPos = 'Next';
            ChangeStimulus(STIMNR);
            Par.SwitchPos = false;
        end
        
        %% update fixation times
        if nf>1 %&& ~Stm(STIMNR).IsPreDur
            dt=lft-prevlft;
            % log the screen flip timing
            Log.dtm=[Log.dtm;dt GetSecs-Par.ExpStart];
            if Par.FixIn % fixating
                Par.FixInOutTime(end,1)=Par.FixInOutTime(end,1)+dt;
            else
                Par.FixInOutTime(end,2)=Par.FixInOutTime(end,2)+dt;
            end
        end
        
        %% Update Tracker window
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
                SCNT(4) = { ['NO MANUAL']};
                SCNT(5) = { ['NO MANUAL']};
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

        %% Stop reward
        StopRewardIfNeeded();
    end
    
    %% Clean up and Save Log ==============================================
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
    
    if ~isempty(Stm(STIMNR).Descript) && ~TestRunstimWithoutDAS
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
        if ~TestRunstimWithoutDAS
            FileName=['Log_' Par.MONKEY '_' Par.STIMSETFILE '_' ...
                Stm(STIMNR).Descript '_' DateString '_Run' num2str(StimLoopNr)];
        else
            FileName=['Log_NODAS_' Par.MONKEY '_' Par.STIMSETFILE '_' ...
                Stm(STIMNR).Descript '_' DateString '_Run' num2str(StimLoopNr)];
        end
        warning off; %#ok<WNOFF>
        if TestRunstimWithoutDAS; cd ..;end
        mkdir('Log');cd('Log');
        StimObj.Stm=Stm;
        % 1st is PreStim, last is PostStim
        Log.FixPerc=100*(Par.FixInOutTime(:,1)./sum(Par.FixInOutTime,2));
        
        mkdir([ Par.MONKEY '_' Par.STIMSETFILE '_' DateString]);
        cd([ Par.MONKEY '_' Par.STIMSETFILE '_' DateString]);
        fn=['Runstim_'  Par.MONKEY '_' Par.STIMSETFILE '_' DateString];
        cfn=[mfilename('fullpath') '.m'];
        copyfile(cfn,fn);
        if ~TestRunstimWithoutDAS
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
            fprintf(fid,['Stimulus: ' Stm(STIMNR).Descript '\n\n']);
            
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
        cd ..
        cd ..
        
        if TestRunstimWithoutDAS; cd Experiment;end
        warning on; %#ok<WNON>
        
        % if running without DAS close ptb windows
        if TestRunstimWithoutDAS
            Screen('closeall');
        end
    end
    
    %% diagnostics to cmd
    if ~Par.ESC && ~TestRunstimWithoutDAS
        GrandTotalReward=GrandTotalReward+Log.TotalReward;
        fprintf(['\nTotal reward this run: ' num2str(Log.TotalReward) '\n']);
        fprintf(['Total reward thusfar: ' num2str(GrandTotalReward) '\n']);
        
        fprintf(['\nTotal time-out this run: ' num2str(Log.TimeOutThisRun) '\n']);
        fprintf(['Total time-out thusfar: ' num2str(Log.TotalTimeOut) '\n']);
        
        CollectPerformance{StimLoopNr,1} = Stm(STIMNR).Descript;
        CollectPerformance{StimLoopNr,2} = nanmean(Log.FixPerc);
        CollectPerformance{StimLoopNr,3} = nanstd(Log.FixPerc)./sqrt(length(Log.FixPerc));
        CollectPerformance{StimLoopNr,4} = Log.TotalReward;
        CollectPerformance{StimLoopNr,5} = Log.TimeOutThisRun;
    elseif Par.ESC && ~LastRewardAdded && ~TestRunstimWithoutDAS
        GrandTotalReward=GrandTotalReward+Log.TotalReward;
        fprintf(['\nTotal reward this run: ' num2str(Log.TotalReward) '\n']);
        fprintf(['Total reward thusfar: ' num2str(GrandTotalReward) '\n']);
        
        fprintf(['\nTotal time-out this run: ' num2str(Log.TimeOutThisRun) '\n']);
        fprintf(['Total time-out thusfar: ' num2str(Log.TotalTimeOut) '\n']);
        
        CollectPerformance{StimLoopNr,1} = Stm(STIMNR).Descript;
        CollectPerformance{StimLoopNr,2} = nanmean(Log.FixPerc);
        CollectPerformance{StimLoopNr,3} = nanstd(Log.FixPerc);
        CollectPerformance{StimLoopNr,4} = Log.TotalReward;
        CollectPerformance{StimLoopNr,5} = Log.TimeOutThisRun;
        LastRewardAdded=true;
    end
end

%% PostExpProcessing ======================================================
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);
Screen('FillRect',Par.window,[0 0 0].*Par.ScrWhite);
Screen('Flip', Par.window);

fprintf('\n\n------------------------------\n');
fprintf('Experiment ended as planned\n');
fprintf('------------------------------\n');

if TestRunstimWithoutDAS
    sca;
    cd Experiment;
    rmpath(genpath(cd));
end

%% close textures to clean memory
if CloseTextures
    fprintf('Cleaning up textures...\n\n');
    for rv = 1:length(ret_vid)
        for jj=1:length(ret_vid(rv).text)
            Screen('Close',ret_vid(rv).text(jj));
        end
    end
end

%% Process performance
if ~isempty(CollectPerformance) && ~TestRunstimWithoutDAS
    ColPerf=[];
    cd Log
    cd([ Par.MONKEY '_' Par.STIMSETFILE '_' DateString]);
    fid2=fopen(['SUMMARY_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString '.txt'],'w');
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
        
        saveas(figperf,['PERFORM_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString],'fig');
        export_fig(['PERFORM_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString],...
            '-pdf','-nocrop',figperf);
        close(figperf);
    end
    save(['PERFORM_' Par.MONKEY '_' Par.STIMSETFILE '_' DateString],'CollectPerformance');
    cd ..;cd ..;
end
clear Log
Par=Par_BU;

%% Standard functions called throughout the runstim =======================
% create fixation window around target
    function DefineEyeWin(STIMNR)
        FIX = 0;  %this is the fixation window
        TALT = 1; %this is an alternative/erroneous target window --> not used
        TARG = 2; %this is the correct target window --> not used
        Par.WIN = [...
            Stm(STIMNR).Center(Par.PosNr,1), ...
            -Stm(STIMNR).Center(Par.PosNr,2), ...
            Stm(STIMNR).FixWinSizePix(1), ...
            Stm(STIMNR).FixWinSizePix(2), FIX]';
        refreshtracker( 1) %clear tracker screen and set fixation and target windows
        SetWindowDas %set das control thresholds using global parameters : Par
    end
% draw fixation
    function DrawFix(STIMNR)
        % fixation area
        rect=[...
            Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(STIMNR).FixDotSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(STIMNR).FixDotSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(STIMNR).FixDotSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(STIMNR).FixDotSizePix/2];
        rect2=[...
            Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(STIMNR).FixDotSurrSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(STIMNR).FixDotSurrSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(STIMNR).FixDotSurrSizePix/2, ...
            Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(STIMNR).FixDotSurrSizePix/2];
        
        Screen('FillOval',Par.window,Par.BG.*Par.ScrWhite,rect2);
        Screen('FillOval',Par.window,Par.CurrFixCol,rect);
        
        cen = [Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1), ...
            Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)];
        
        if strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            if Par.ResponseState == Par.RESP_STATE_DONE && ...
                    ~Par.CanStartTrial(Par) && ...
                    GetSecs >= Par.ResponseStateChangeTime + 500/1000
                if Par.DrawBlockedInd
                    Screen('FillOval',Par.window, Par.BlockedIndColor.*Par.ScrWhite, ...
                        [cen,cen] + Par.RespIndSizePix*blocked_circle)
                end
            elseif Par.ResponseSide == 1
                Screen('FillPoly',Par.window, Par.RespIndColor(1,:).*Par.ScrWhite, ...
                    [cen;cen;cen;cen] + Par.RespIndSizePix*left_square)
            elseif Par.ResponseSide == 2
                Screen('FillPoly',Par.window, Par.RespIndColor(2,:).*Par.ScrWhite, ...
                    [cen;cen;cen;cen] + Par.RespIndSizePix*right_diamond)
            end
        end
    end
% draw "go bar" 
    function DrawGoBar(STIMNR)
        if Par.ResponseSide==0
            return
        end
        % Target bar
        %if ~Par.Orientation(Par.CurrOrient) 
        if Par.ResponseState == Par.RESP_STATE_GO  %horizontal 
            rect=[...
                Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)-Par.GoBarSizePix(1)/2, ...
                Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)-Par.GoBarSizePix(2)/2, ...
                Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)+Par.GoBarSizePix(1)/2, ...
                Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)+Par.GoBarSizePix(2)/2];
            Screen('FillRect',Par.window,Par.GoBarColor.*Par.ScrWhite,rect);
            
        elseif Par.ResponseState == Par.RESP_STATE_WAIT %vertical
            rect=[...
                Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)-Par.GoBarSizePix(2)/2, ... left
                Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)-Par.GoBarSizePix(1)/2, ... top
                Stm(STIMNR).Center(Par.PosNr,1)+Par.ScrCenter(1)+Par.GoBarSizePix(2)/2, ... right
                Stm(STIMNR).Center(Par.PosNr,2)+Par.ScrCenter(2)+Par.GoBarSizePix(1)/2];
            Screen('FillRect',Par.window,Par.GoBarColor.*Par.ScrWhite,rect);
        end
    end
% draw stimuli
    function DrawStimuli
        % Background
        Screen('FillRect',Par.window,ceil(Par.BG.*Par.ScrWhite));
    end
% auto-dim the screen if hand is out
    function AutoDim
        if Par.HandOutDimsScreen && ~Par.HandIsIn
            Screen('FillRect',Par.window,...
                [0 0 0 (Par.HandOutDimsScreen_perc)].*Par.ScrWhite,....
                [Par.wrect(1:2) Par.wrect(3:4)+1]);
        end
    end
% change stimulus features
    function ChangeStimulus(STIMNR)
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
            DefineEyeWin(STIMNR);
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
                    case Par.KeyJuice
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            Par.ManualReward = true;
                            Log.ManualRewardTime = ...
                                [Log.ManualRewardTime; Par.KeyTime];
                        end
                    case Par.KeyStim
                        if Par.KeyDetectedInTrackerWindow % only in Tracker
                            if ~Par.ToggleHideStim;
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
                            if ~Par.ToggleHideFix;
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
        Log.RespSignal = ChanLevels(...
            Par.ConnectBox.PhotoAmp(Par.ConnectBox.PhotoAmp_used)-2);
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
        Par.BeamIsBlocked = (Log.RespSignal > Threshold)==0;
        
        % Log any changes
        if any(Par.BeamWasBlocked(:) ~= Par.BeamIsBlocked(:))
            Log.nEvents=Log.nEvents+1;
            Log.Events(Log.nEvents).type=...
                strcat('BeamStateChange ', mat2str(Par.BeamIsBlocked));
            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
        end
        
        if ~strcmp(Par.ResponseBox.Task, 'DetectGoSignal')
            % interpret depending on response box type
            switch Par.ResponseBox.Type
                case 'Beam'
                    if strcmp(Par.HandSignalBothOrEither, 'Both') && ...
                            mean(Par.BeamIsBlocked)<1 % at least 1 not blocked
                        if Par.HandIsIn
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandOut';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=false;
                        end
                    elseif strcmp(Par.HandSignalBothOrEither, 'Either') && ...
                            mean(Par.BeamIsBlocked)==0 % neither blocked
                        if Par.HandIsIn
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandOut';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=false;
                        end
                    else
                        if ~Par.HandIsIn
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandIn';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=true;
                        end
                    end
                case 'Lift'
                    if strcmp(Par.HandSignalBothOrEither, 'Both') && ...
                            mean(Par.BeamIsBlocked)==1 % both blocked
                        if ~Par.HandIsIn
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandIn';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=true;
                        end
                    elseif strcmp(Par.HandSignalBothOrEither, 'Either') && ...
                            mean(Par.BeamIsBlocked)>0 % at least one blocked
                        if ~Par.HandIsIn
                            % only do this if 1 channel is used
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandIn';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=true;
                        end
                    else
                        if Par.HandIsIn
                            Log.nEvents=Log.nEvents+1;
                            Log.Events(Log.nEvents).type='HandOut';
                            Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                            Par.HandIsIn=false;
                        end
                    end
            end
        end
    end
% give automated reward
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
            Par.RewardTimeCurrent = Par.RewardFixMultiplier * Par.RewardTimeCurrent;
            if Par.RewardFixMultiplier <= 0 % no reward given if true
                return
            end
        end
        
        if size(Par.Times.Targ,2)>1;
            rownr= find(Par.Times.Targ(:,1)<Par.CorrStreakcount(2),1,'last');
            Par.Times.TargCurrent=Par.Times.Targ(rownr,2);
        else
            Par.Times.TargCurrent=Par.Times.Targ;
        end
        
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
% give manual reward
    function GiveRewardAutoTask
        if ~isempty(Par.RewardTaskMultiplier)
            Par.RewardTimeCurrent = Par.RewardTaskMultiplier * Par.RewardTime;
        else
            Par.RewardTimeCurrent = Par.RewardTime;
        end
        % Give the reward
        Par.RewardStartTime=GetSecs;
        if strcmp(computer,'PCWIN64')
            dasjuice(10); % 64bit das card
        else
            dasjuice(5) %old card dasjuice(5)
        end
        Par.RewardRunning=true;
        
%         % Play back a sound
%         if Par.RewardSound
%             RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
%             RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
%             sound(RewY,Par.RewSndPar(1));
%         end
        
        Log.nEvents=Log.nEvents+1;
        Log.Events(Log.nEvents).type='RewardAutoTask';
        Log.Events(Log.nEvents).t=GetSecs-Par.ExpStart;
        Log.Events(Log.nEvents).StimName = [];
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
% create radial checkerboard
    function chkimg = RadialCheckerBoard(radius, sector, chsz)
        %img = RadialCheckerBoard(radius, sector, chsz, propel)
        % Returns a bitmap image of a radial checkerboard pattern.
        % The image is a square of 2*OuterRadius pixels.
        %
        % Parameters of wedge:
        %   radius :    eccentricity of radii in pixels = [outer, inner]
        %   sector :    polar angles in degrees = [start, end] from -180 to 180
        %   chsz :      size of checks in log factors & degrees respectively = [eccentricity, angle]
        %   propel :    Optional, if defined there are two wedges, one in each hemifield
        %
        checkerboard = [0 Par.ScrWhite; Par.ScrWhite 0];
        img = ones(2*radius(1), 2*radius(1)) * ceil(Par.ScrWhite/2);
        
        for x = -radius : radius
            for y = -radius : radius
                [th, r] = cart2pol(x,y);
                th = th * 180/pi;
                if th >= sector(1) && th < sector(2) && r < radius(1) && r > radius(2)
                    img(y+radius(1)+1,x+radius(1)+1) = checkerboard(mod(floor(log(r)*chsz(1)),2) + 1, mod(floor((th + sector(1))/chsz(2)),2) + 1);
                end
            end
        end
        img = flipud(img);
        
        if nargin > 3
            rotimg = rot90(img,2);
            non_grey_pixels = find(rotimg ~= ceil(Par.ScrWhite/2));
            img(non_grey_pixels) = rotimg(non_grey_pixels);
        end
        img = uint8(img);
        
        width = radius(1)*2;
        [X, Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
        [T, R] = cart2pol(X,Y);
        circap = ones(width, width);
        circap(R > width/2) = 1;
        alphas = linspace(1, 0, 0);
        circap(R > width/2) = 0;
        circap(R < radius(2)) = 0;
        chkimg = img;
        chkimg(:,:,2) = uint8(abs(double(img)-Par.ScrWhite));
        chkimg(:,:,3)=circap.*Par.ScrWhite;
    end
% check eye only (dascheck without tracker gui update)
    function [Hit, Time] = DasCheckEyeOnly
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
end