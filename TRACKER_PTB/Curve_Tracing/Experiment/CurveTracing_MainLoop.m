function CurveTracing_MainLoop(tasksToCycle, maxTrials, args)
global Par;
global Log;
global StimObj;

Stm = StimObj.Stm;

lft = Par.lft;

if isfield(args, 'maxTimeSecs')
    stopAt = GetSecs + args.maxTimeSecs;
else
    stopAt = Inf;
end

for trial_iter = 1:maxTrials % ------------------------ for each trial ----
    if Par.ESC || GetSecs >= stopAt 
        Par.ESC = true;
        break
    end
    
    if trial_iter == 1 || Stm(1).task.endOfBlock() % ------- Start new block?
        if trial_iter > 1 && Par.Verbosity >= 1
            % Display information from previous task
            CHR = Stm(1).task.trackerWindowDisplay();
            fprintf('%s\n', CHR{:});
        end
        
        Log.numMiniBlocks = Log.numMiniBlocks + 1;
        
        if args.alternateWithRestingBlocks && ...
                Stm(1).task ~= Stm(1).RestingTask
            Stm(1).taskCycleInd = NaN;
            Stm(1).task = Stm(1).RestingTask;
        else
            Stm(1).taskCycleInd = randi(length(tasksToCycle));
            Stm(1).task = tasksToCycle{Stm(1).taskCycleInd};
        end
        
        fprintf('-- Start mini-block %d: %s --\n', Log.numMiniBlocks, Stm(1).task.name);
        Log.events.add_entry(lft, Stm(1).task.name, 'NewMiniBlock', num2str(Log.numMiniBlocks));
    end
    
    % ----------------------------------------------- Start new trial -----
    Stm(1).task.updateState('INIT_TRIAL', lft);

       
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.CurrResponse = Par.RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    Par.TrialResponse = false;
    
    % Eye Window preparation ----------------------------------------------
    for PrepareEyeWin=1
        DefineEyeWin;
    end
    if ~Par.TestRunstimWithoutDAS
        dasreset( 0 );
    end
    
    % Check eye fixation --------------------------------------------------
    CheckFixation;
    
    % Wait for fixation ---------------------------------------------------
    Stm(1).task.updateState('PREFIXATION', lft);
    Par.FixStart=Inf;
    %fprintf('Start %s task\n', Stm(1).task.name);
    
    % ---------------------------------------------------------------------
    %
    %                       WITHIN-TRIAL LOOP
    %
    %     Go through all of the different states of the current trial
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    while ~Stm(1).task.endOfTrial() && ~Par.PosReset && ~Par.endExperiment && ~Par.BreakTrial
        
        % If subject has not started fixating by the time the trials should
        % end, go ahead and stop.
        if Par.FixStart==Inf && GetSecs >= stopAt
            Par.ESC = true;
            break;
        end
        
        CheckManual;
        Stm(1).task.checkResponses(GetSecs);
        CheckKeys;
        lft = Stm(1).task.drawStimuli(lft);
        
        %% log eye-info if required
        LogEyeInfo;
        
        CheckFixation;
        CheckTracker; % Get and plot eye position
        ChangeStimulus; % Change stimulus if required (e.g. fixation moved).
        
        % give manual reward
        if Par.ManualReward
            GiveRewardManual;
            Par.ManualReward=false;
        end
        
        % Check eye position
        %CheckTracker(); % just for plotting
        CheckFixation;
        
        % give automated reward
        if Par.GiveRewardAmount > 0 % Par.RespValid && ~Par.AutoRewardGiven
            GiveRewardAuto;
            Par.AutoRewardGiven = true;
        end
    end
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    %
    %                     END WITHIN-TRIAL LOOP
    %
    % ---------------------------------------------------------------------
    
    % no response or fix break during switch = miss
    % ~Par.ResponseGiven && ~Par.FalseResponseGiven && ...
    if Par.CurrResponse == Par.RESP_NONE            
        Par.CurrResponse = Par.RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.CorrStreakcount=[0 0];
    end
    
    % Performance info on screen
    for PerformanceOnCMD=1
        if Par.PosReset
            Log.events.add_entry(lft, Stm(1).task.name, 'PosReset');
            
            % reset
            Par.Trlcount(1) = 0;
            Par.CorrStreakcount(1)=0;
            Par.PosReset=false; %start new trial when switching position
        else
            Log.events.add_entry(lft, Stm(1).task.name, 'TrialCompleted');
        end
    end
    
    % Update Tracker window
    if ~Par.TestRunstimWithoutDAS
        SCNT = Stm(1).task.trackerWindowDisplay();
        set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
        % Give noise-on-eye-channel info
        SD = dasgetnoise();
        SD = SD./Par.PixPerDeg;
        set(Hnd(2), 'String', SD )
    end
end

% = = =                                                               = = =
% =                           END MAIN LOOP                               =
% =                                                                       =
% =========================================================================

%% Standard functions called throughout the runstim =======================
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

    function CheckFixation
        % Check if eye enters fixation window =============================
        if ~Par.FixIn %not fixating
            if ~Par.CheckFixIn && ~Par.TestRunstimWithoutDAS
                dasreset(0); % start testing for eyes moving into fix window
            end
            Par.CheckFixIn=true;
            Par.CheckFixOut=false;
            Par.CheckTarget=false;
            
            % Load retinotopic mapping stimuli - none to load
            LoadStimuli=false;
            
            % Check eye position
            fixChange = CheckTracker;
            
            if fixChange % eye in fix window (hit will never be 1 is tested without DAS)
                Par.FixIn=true;
                Par.LastFixInTime=GetSecs;
                Stm(1).task.fixation_in(Par.LastFixInTime);
                
                % Par.Trlcount=Par.Trlcount+1;
                refreshtracker(3);
            end
            if mod(Par.nf,100)==0 && ~Par.TestRunstimWithoutDAS
                refreshtracker(1);
                Par.nf = Par.nf + 1;
            end
        end
        % Check if eye leaves fixation window =============================
        if Par.FixIn %fixating
            if ~Par.CheckFixOut && ~Par.TestRunstimWithoutDAS
                dasreset(1); % start testing for eyes leaving fix window
            end
            Par.CheckFixIn=false;
            Par.CheckFixOut=true;
            Par.CheckTarget=false;
            
            % Check eye position
            % DasCheck
            fixChange = CheckTracker;
            
            if fixChange % eye out of fix window
                Par.FixIn=false;
                Par.LastFixOutTime=GetSecs;
                
                Stm(1).task.fixation_out(Par.LastFixOutTime);
                
                refreshtracker(1);
                
                Log.events.add_entry(Par.LastFixOutTime, Stm(1).task.name, 'Fixation', 'Out');
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
        end
    end
end
