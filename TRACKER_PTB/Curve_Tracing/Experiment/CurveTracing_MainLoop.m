function CurveTracing_MainLoop(Hnd, tasksToCycle, maxTrials, args)
global Par;
global Log;
global StimObj;

Stm = StimObj.Stm;

lft = Par.lft;
% For ending times that can be controlled by keyboard
% Does not interrupt trial in progress
Par.noNewTrialsAfter = Inf;
if isfield(args, 'noNewBlocksAfterTime')
    Par.noNewBlocksAfterTime = args.noNewBlocksAfterTime;
else
    Par.noNewBlocksAfterTime = Inf;
end

% stopAt does interrupt trials, but gives some reward
if isfield(args, 'maxTimeSecs')
    stopAt = GetSecs + args.maxTimeSecs;
else
    stopAt = Inf;
end

for trial_iter = 1:maxTrials % ------------------------ for each trial ----
    if Par.ESC || GetSecs >= stopAt || GetSecs >= Par.noNewTrialsAfter
        Par.ESC = true;
        
        Stm(1).task.updateState('TRIAL_END', GetSecs);
        Par.lft = Stm(1).task.drawStimuli(Par.lft);
        break
    end
    
    if trial_iter == 1 || Stm(1).task.endOfBlock() % ------- Start new block?
        if GetSecs > Par.noNewBlocksAfterTime
            Par.ESC = true;
            Log.events.add_entry(Par.lft, Stm(1).task.name, ...
                'NoNewBlocksAfterTime', num2str(Par.noNewBlocksAfterTime));
            Par.lft = Stm(1).task.drawStimuli(Par.lft);
            break
        end
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
        elseif Stm(1).iterateTasks
            Stm(1).taskCycleInd = mod(Stm(1).taskCycleInd, length(tasksToCycle)) + 1;
            Stm(1).task = tasksToCycle{Stm(1).taskCycleInd};
        else
            Stm(1).taskCycleInd = randi(length(tasksToCycle));
            Stm(1).task = tasksToCycle{Stm(1).taskCycleInd};
        end
        
        fprintf('-- Start mini-block %d: %s --\n', Log.numMiniBlocks, Stm(1).task.name);
        Log.events.add_entry(Par.lft, Stm(1).task.name, 'NewMiniBlock', num2str(Log.numMiniBlocks));
        
        Par.CorrStreakcount(1) = 0; % Reset the per-block streak count
    end
    
    % ----------------------------------------------- Start new trial -----
    Stm(1).task.updateState('INIT_TRIAL', Par.lft);
       
    Par.Trlcount = Par.Trlcount+1; %keep track of trial numbers
    Par.AutoRewardGiven=false;
    Par.CurrResponse = Par.RESP_NONE;
    Par.ResponseGiven=false;
    Par.FalseResponseGiven=false;
    Par.RespValid = false;
    Par.CorrectThisTrial=false;
    Par.BreakTrial=false;
    Par.TrialResponse = false;
    Par.HandRemoved = false;
    
    % Eye Window preparation ----------------------------------------------
    for PrepareEyeWin=1
        DefineEyeWin;
    end
    if ~Par.TestRunstimWithoutDAS
        dasreset( 0 );
    end
    
    while ~Par.ESC && (~Par.GoNewTrial) % Par.Pause || 
        CheckManual(Stm);
        CheckKeys;
        Par.lft = Stm(1).task.drawStimuli(Par.lft);
        CheckFixation;
        CheckTracker; % Get and plot eye position
    end
    
    % Check eye fixation --------------------------------------------------
    CheckFixation;
    
    % Wait for fixation ---------------------------------------------------
    Stm(1).task.updateState('PREFIXATION', Par.lft);
    Par.FixStart=Inf;
    %fprintf('Start %s task\n', Stm(1).task.name);
    
    % ---------------------------------------------------------------------
    %
    %                       WITHIN-TRIAL LOOP
    %
    %     Go through all of the different states of the current trial
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    while ~Stm(1).task.endOfTrial() && ~Par.PosReset && ~Par.endExperiment && ~Par.BreakTrial  %&& ~Par.Pause
        if GetSecs >= stopAt || Par.ESC
            if Par.FixStart ~= Inf
                % Give subject a reward if not waiting for fixation
                % Might be interrupting subject while performing task
                GiveRewardManual;
                Par.ManualReward=false;
            end
            Par.ESC = true;
            break;
        end
        
        CheckManual(Stm);
        Stm(1).task.checkResponses(GetSecs);
        CheckKeys;
        Par.lft = Stm(1).task.drawStimuli(Par.lft);
        
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
    if Par.HandRemoved
        Par.CurrResponse = Par.RESP_REMOVE_HAND;
        
    elseif Par.CurrResponse == Par.RESP_NONE
        Par.CurrResponse = Par.RESP_MISS;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
    end
    
    if Par.CurrResponse ~= Par.RESP_CORRECT
        Par.CorrStreakcount = [0 0];
    end
    
    % Performance info on screen
    for PerformanceOnCMD=1
        if Par.PosReset
            Log.events.add_entry(Par.lft, Stm(1).task.name, 'PosReset');
            
            % reset
            Par.Trlcount(1) = 0;
            Par.PosReset=false; %start new trial when switching position
        else
            Log.events.add_entry(Par.lft, Stm(1).task.name, 'TrialCompleted');
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
