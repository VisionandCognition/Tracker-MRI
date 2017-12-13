classdef FixationTask < FixationTrackingTask
    %FIXATIONTASK Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = protected)
        taskName = 'Fixation'
        stimuli_params; % parameters for each individual stimulus
        state = NaN;
        curr_stim = NaN; % save randomizations
        
        currStateStart = -Inf; 
        stateStart = struct('PREFIXATION', -Inf, 'FIXATION_PERIOD', -Inf, 'POSTFIXATION', -Inf);
        
        iTrialOfBlock = 1;
        iSubtrial = 0;
        
        curr_response = 'none'; % response of current trial
        responses = struct(...
            'correct', [0], ...
            'break_fix', [0]);
    end
    properties (Access = public)
        taskParams; % parameters that apply to every stimulus
    end
    methods
        function name = name(obj)
            name = obj.taskName;
        end
        function time = stateStartTime(obj, state)
            time = obj.stateStart.(state);
        end
        function obj = FixationTask(commonParams)
            % INPUT commonParams: should be a container.Map
            obj.taskParams = commonParams;
            obj.stimuli_params = table();
        end
        
        drawCurve(obj, pos, connection1, connection2, indpos, Par, Stm);
        drawPreSwitchFigure(obj, Par, pos, SizePix, alpha);
        lft = drawStimuli(obj, lft);
        
        function updateState(obj, state, time)
            global Log;
            obj.state = state;

            obj.currStateStart = time;
            obj.stateStart.(obj.state) = time;
            
            Log.events.add_entry(time, obj.taskName, 'DecideNewState', obj.state);
            Log.events.queue_entry(obj.taskName, 'NewState', obj.state);

            %fprintf('New state: %s\n', state);
            obj.update();
        end
        function isEnd = endOfTrial(obj)
            STR_IDENTICAL = true;
            isEnd = (strcmp(obj.state, 'TRIAL_END') == STR_IDENTICAL);
        end
        function isEnd = endOfBlock(obj)
            if ~obj.endOfTrial()
                isEnd = false;
            else
                isEnd = obj.iTrialOfBlock >= obj.param('BlockSize');
            end
        end
        
        function checkResponses(obj, time)
            global Par;
            global Log;
            if strcmp(obj.state, 'POSTFIXATION')
                if time > obj.stateStart.POSTFIXATION + obj.taskParams.postfixPeriod/1000
                    obj.responses.(obj.curr_response) = obj.responses.(obj.curr_response) + 1;
                    obj.updateState('TRIAL_END', time);
                end
            end
            if strcmp(obj.state, 'PREFIXATION')
                if time > obj.stateStart.PREFIXATION + obj.taskParams.prefixPeriod/1000 && ...
                        (Par.FixIn || ~Par.WaitForFixation)
                    obj.updateState('FIXATION_PERIOD', time);
                    obj.startTrackingFixationTime(time, Par.FixIn);
                end
            end
            if strcmp(obj.state, 'FIXATION_PERIOD')
                if time > obj.stateStart.FIXATION_PERIOD + obj.taskParams.fixationPeriod/1000
                    obj.updateState('POSTFIXATION', time);
                    obj.stopTrackingFixationTime(time);

                    fixInRatio = obj.fixation_ratio();

                    if Par.Verbosity >= 2
                        fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f)\n', fixInRatio, ...
                            obj.time_fixating(), obj.time_not_fixating());
                    end

                    if fixInRatio >= 0.90
                        RewardAmount = Par.GiveRewardAmount + ...
                            fixInRatio^2 * Par.RewardTime * obj.taskParams.rewardMultiplier;

                        obj.curr_response = 'correct';
                        Par.CurrResponse = Par.RESP_CORRECT;

                        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;

                        Par.GiveRewardAmount = Par.GiveRewardAmount + RewardAmount;
                        Log.events.add_entry(time, obj.taskName, 'ResponseGiven', 'CORRECT');
                        Log.events.add_entry(time, obj.taskName, 'ResponseReward', num2str(RewardAmount));
                    else
                        obj.curr_response = 'break_fix';
                        Par.CurrResponse = Par.RESP_BREAK_FIX;
                    end
                    
                    if obj.taskParams.postfixPeriod == 0
                        obj.responses.(obj.curr_response) = obj.responses.(obj.curr_response) + 1;
                        
                        obj.update_InitSubtrial();
                        
                        if obj.iSubtrial > 0 % obj.iTrialOfBlock < obj.param('BlockSize')
                            obj.set_param('FixationPeriodTime', ...
                                obj.taskParams.EventPeriods(1)/1000 + ...
                                rand(1)*obj.taskParams.EventPeriods(2)/1000);

                            obj.updateState('FIXATION_PERIOD', time);
                            obj.startTrackingFixationTime(time, Par.FixIn);
                        else
                            obj.updateState('TRIAL_END', time);
                        end
                    end
                end
            end
        end
        function [val, status] = param(obj, var)
            % first look for parameter in current stimulus conditions
            try
                val = obj.curr_stim(var);
                status = true;
            catch ME
                % Remember: STRCMP behaves as "STREQUAL", not as it should
                if ~strcmp(ME.identifier, 'MATLAB:Containers:Map:NoKey') && ...
                        ~strcmp(ME.identifier, 'MATLAB:badsubscript')
                    rethrow(ME);
                end
                if isfield(obj.taskParams, var)
                    val = obj.taskParams.(var);
                    status = true;
                else
                    val = nan;
                    status = false;
                end
            end
            if nargout < 2 && ~status
                % if calling function doesn't get the status value and
                %   it is false, throw an error.
                error('Parameter variable %s does not exist!', var);
            end
        end
        function obj = set_param(obj, var, val)
            if ~isa( obj.curr_stim, 'containers.Map')
                obj.curr_stim = containers.Map;
            end
            obj.curr_stim(var) = val;
        end
        function SCNT = trackerWindowDisplay(obj)
            SCNT(1) = { obj.taskName };
            SCNT(2) = { ['Cor:  ' num2str( round( ...
                obj.responses.correct / obj.taskParams.subtrialsInTrial, 2)) ] };
            SCNT(3) = { ['Fix. break:  ' num2str( round( ...
                obj.responses.break_fix / obj.taskParams.subtrialsInTrial, 2)) ] };
        end
        function write_trial_log_csv(~, ~)
            % do nothing
        end
    end
    methods(Access = protected)
        update_PrepareStim(obj);
        drawFix(obj);
        drawBackgroundFixPoint(obj);
        
        function update(obj)          
            switch obj.state
                case 'PREPARE_STIM'
                    obj.update_PrepareStim();
                case 'INIT_TRIAL'
                    obj.update_InitSubtrial();
                    
                    fprintf('Trial %s.%s', obj.iTrialOfBlock, obj.iSubtrial);
                    obj.set_param('FixationPeriodTime', ...
                        obj.taskParams.EventPeriods(1)/1000 + ...
                        rand(1)*obj.taskParams.EventPeriods(2)/1000);
            end
        end
        function update_InitSubtrial(obj)
            obj.curr_response = 'none';
            obj.iSubtrial = obj.iSubtrial + 1;
            % if finished with all subtrials of a trial, increment trial
            if obj.iSubtrial > obj.taskParams.subtrialsInTrial
                obj.iSubtrial = 0;
                obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
            end
        end
    end
    
end


