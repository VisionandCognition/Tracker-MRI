function runstim(Hnd)
% Updated September 2013 Chris Klink
% Manual response photocell on channel 3 of connection box

global Par   %global parameters
global StimObj %stimulus objects
global Log
clc;

% re-run parameter-file to update stim-settings without restarting Tracker
%ParSettings; % this is the old way of hardcoding a ParSettings file
eval(Par.PARSETFILE); % this takes the ParSettings file chosen via the context menu

Stm = StimObj.Stm;

%% Stimulus preparation ===================================================
for PrepareStim=1
    % Fixation
    Stm(1).FixWinSizePix = round(Stm(1).FixWinSize*Par.PixPerDeg);
    
    % Bar
    Stm(1).SizePix = round(Stm(1).Size.*Par.PixPerDeg);
    Stm(1).Center =[];
    for i=1:size(Stm(1).Position,2);
        Stm(1).Center =[Stm(1).Center; ...
            round(Stm(1).Position{i}.*Par.PixPerDeg)];
    end
    Par.CurrOrient=1; % 1=default, 2=switched
    
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
    Par.BeamIsBlocked=false;
    Par.BeamWasBlocked=false;
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
    Par.Response = [0 0 0]; %[correct false-hit missed]
    Par.ResponsePos = [0 0 0]; %[correct false-hit missed]
    Par.RespTimes = [];
    Par.ManRewThisTrial=[];
end

%% Stimulus presentation loop =============================================
% keep doing this until escape is pressed or stop is clicked
% Structure: preswitch_period-switch_period/switched_duration-postswitch
while ~Par.ESC %===========================================================
    %set control window positions and dimensions
    DefineEyeWin;
    refreshtracker(1) %for your control display
    SetWindowDas      %for the dascard, initializes eye control windows
    
    % If required, pause here until beam is no longer interrupted
    if Stm(1).OnlyStartTrialWhenBeamIsNotBlocked
        while ~Par.GoNewTrial && ~Par.ESC
            CheckManual;
            CheckKeys;
            DrawNoiseOnly;
        end
    end
    
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    
    % Eye Window preparation ----------------------------------------------
    for PrepareEyeWin=1
        DefineEyeWin;
    end
    dasreset( 0 );
    
    % PRESWITCH -----------------------------------------------------------
    Par.PreSwitchStart=lft;
    Par.SwitchOnset=rand(1)*Stm(1).EventPeriods(2)/1000;
    while lft < Par.PreSwitchStart + ...
            Stm(1).EventPeriods(1)/1000 + Par.SwitchOnset && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli
        DrawStimuli;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse
            % false hit
            Par.RespValid = false;
            Par.Response(2)=Par.Response(2)+1;
            Par.ResponsePos(2)=Par.ResponsePos(2)+1;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
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
    Par.SwitchStart=lft;
    % switch to orientation 2
    Par.CurrOrient=2;
    % switched
    while lft < Par.SwitchStart+Stm(1).SwitchDur/1000 && ...
            ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli
        DrawStimuli;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse && ...
                lft >= Par.SwitchStart+Stm(1).ResponseAllowed(1)/1000 && ...
                lft < Par.SwitchStart+Stm(1).ResponseAllowed(2)/1000
            % correct
            Par.RespValid = true;
            if ~Par.ResponseGiven %only log once
                Par.Response(1)=Par.Response(1)+1;
                Par.ResponsePos(1)=Par.ResponsePos(1)+1;
                Par.CorrectThisTrial=true;
            end
            Par.ResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            Par.CorrStreakcount=Par.CorrStreakcount+1;
        elseif Par.NewResponse  
            % false
            Par.RespValid = false;
            Par.Response(2)=Par.Response(2)+1;
            Par.ResponsePos(2)=Par.ResponsePos(2)+1;
            Par.FalseResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            if Stm(1).BreakOnFalseHit
                Par.BreakTrial=true;
            end
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
    % switch to orientation 1
    Par.CurrOrient=1;
    
    % POSTSWITCH ----------------------------------------------------------
    Par.PostSwitchStart=lft;
    
    while lft < Par.PostSwitchStart + ...
            Stm(1).EventPeriods(3)/1000 && ~Par.PosReset && ...
            ~Par.ESC && ~Par.BreakTrial
        
        % DrawStimuli
        DrawStimuli;
        
        % check for key-presses
        CheckKeys; % internal function
        
        % check for manual responses
        CheckManual;
        if Par.NewResponse && ...
                lft < Par.PostSwitchStart+Stm(1).ResponseAllowed(2)/1000
            % correct
            Par.RespValid = true;
            if ~Par.ResponseGiven %only log once
                Par.Response(1)=Par.Response(1)+1;
                Par.ResponsePos(1)=Par.ResponsePos(1)+1;
                Par.CorrectThisTrial=true;
            end
            Par.ResponseGiven=true;
            Par.RespTimes=[Par.RespTimes;
                lft-Par.ExpStart Par.RespValid];
            Par.CorrStreakcount=Par.CorrStreakcount+1;
        elseif Par.NewResponse
            % False hit
            Par.RespValid = false;
            Par.FalseResponseGiven=true;
            Par.Response(2)=Par.Response(2)+1;
            Par.ResponsePos(2)=Par.ResponsePos(2)+1;
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
    % no response during switch = miss
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven
        Par.Response(3)=Par.Response(3)+1;
        Par.ResponsePos(3)=Par.ResponsePos(3)+1;
        Par.CorrStreakcount=[0 0];
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
            Par.ResponsePos = [0 0 0];
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
        end
    end
    
    % Update Tracker window
    SCNT = {'TRIALS'};
    SCNT(2) = { ['T: ' num2str(Par.Trlcount(2)) ]};
    SCNT(3) = { ['C: ' num2str(Par.Response(1)) ] };
    SCNT(4) = { ['M: ' num2str(Par.Response(3)) ] };
    SCNT(5) = { ['F: ' num2str(Par.Response(2)) ] };
    set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
    % Give noise-on-eye-channel info
    SD = dasgetnoise();
    SD = SD./Par.PixPerDeg;
    set(Hnd(2), 'String', SD )
end

%% Clean up and Save Log ==================================================
for CleanUp=1 % code folding
    % Empty the screen
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    
    % save stuff
    FileName=['Log' datestr(clock,30)];
    warning off; %#ok<WNOFF>
    mkdir('Log');cd('Log');
    save(FileName,'Log','Par','StimObj');
    cd ..
    warning on; %#ok<WNON>
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
        SetWindowDas %set das control thresholds using global parameters : Par
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
        
        % Target bar
        if ~Stm(1).Orientation(Par.CurrOrient) %horizontal
            rect=[...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(1)/2, ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(2)/2, ...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(1)/2, ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).SizePix(2)/2];
        else
            rect=[...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(2)/2, ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(1)/2, ...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(2)/2, ...
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
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
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
        %check the incoming signal on DAS channel #3
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
            Par.BeamIsBlocked = false;
            if Par.HandIsIn
                Par.HandIsIn=false;
            end
        elseif strcmp(computer,'PCWIN') && Log.RespSignal > 2750 % old das card 
            Par.BeamIsBlocked = false;
            if Par.HandIsIn
                Par.HandIsIn=false;
            end    
        else
            Par.BeamIsBlocked = true;
            if ~Par.HandIsIn
                Par.HandIsIn=true;
            end
        end 
        
        % interpret
        if Par.BeamIsBlocked && ~Par.BeamWasBlocked
            Par.NewResponse = true;
            Par.BeamWasBlocked = true;
            Par.GoNewTrial = false;
        elseif Par.BeamIsBlocked && Par.BeamWasBlocked
            Par.NewResponse = false;
            Par.GoNewTrial = false;
        elseif ~Par.BeamIsBlocked && Par.BeamWasBlocked
            % key is released
            Par.BeamWasBlocked = false;
            Par.NewResponse = false;
            Par.GoNewTrial = true;
        elseif ~Par.BeamIsBlocked && ~Par.BeamWasBlocked
            Par.GoNewTrial = true;
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
end