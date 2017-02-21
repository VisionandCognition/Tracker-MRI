classdef FixationTask < FixationTrackingTask
    %FIXATIONTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        taskName = 'Fixation'
    end
    properties (Access = private)
        stimuli_params; % parameters for each individual stimulus
        state = NaN;
        curr_stim = NaN; % save randomizations
        
        currStateStart = -Inf; 
        stateStart = struct('PREFIXATION', -Inf, 'FIXATION_PERIOD', -Inf, 'POSTFIXATION', -Inf);
        
        iTrialOfBlock = 0;
    end
    properties (Access = public)
        taskParams; % parameters that apply to every stimulus
    end
    methods
        function time = stateStartTime(obj, state)
            time = obj.stateStart.(state);
        end
        function obj = FixationTask(commonParams)
            % INPUT commonParams: should be a container.Map
            obj.taskParams = commonParams;
            obj.stimuli_params = table();
        end
        
        drawFix(obj);
        drawBackgroundFixPoint(obj);
        drawCurve(obj, pos, connection1, connection2, indpos, Par, Stm);
        drawPreSwitchFigure(obj, Par, pos, SizePix, alpha);
        lft = drawStimuli(obj, lft);
        drawTarget(obj, color, offset, which_side);
        
        function updateState(obj, state, time)
            global Log;
            obj.state = state;

            obj.currStateStart = time;
            obj.stateStart.(obj.state) = time;
            Log.events.add_entry(time, 'NewState', obj.state);

            %fprintf('New state: %s\n', state);
            obj.update();
        end
        function isEnd = endOfTrial(obj)
            STR_IDENTICAL = true;
            isEnd = (strcmp(obj.state, 'END_TRIAL') == STR_IDENTICAL);
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
            switch obj.state
                case 'PREFIXATION'
                    if time > obj.stateStart.PREFIXATION + obj.taskParams.prefixPeriod/1000
                        obj.updateState('FIXATION_PERIOD', time);
                        obj.startTrackingFixationTime(time, Par.FixIn);
                    end
                case 'FIXATION_PERIOD'
                    if time > obj.stateStart.FIXATION_PERIOD + obj.taskParams.fixationPeriod/1000
                        obj.updateState('POSTFIXATION', time);
                        obj.stopTrackingFixationTime(time);
                        
                        fixInRatio = obj.fixation_ratio();

                        fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f)\n', fixInRatio, ...
                            obj.time_fixating(), obj.time_not_fixating());

                        if fixInRatio >= 0.1
                            RewardAmount = Par.GiveRewardAmount + ...
                                fixInRatio^2 * Par.RewardTime * obj.taskParams.rewardMultiplier;

                            Par.CurrResponse = Par.RESP_CORRECT;
                            
                            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;

                            Par.GiveRewardAmount = Par.GiveRewardAmount + RewardAmount;
                            Log.events.add_entry(time, 'ResponseGiven', 'CORRECT');
                            Log.events.add_entry(time, 'ResponseReward', RewardAmount);
                        else
                            Par.CurrResponse = Par.RESP_BREAK_FIX;
                        end
                    end
                case 'POSTFIXATION'
                    if time > obj.stateStart.POSTFIXATION + obj.taskParams.postfixPeriod/1000
                        obj.updateState('END_TRIAL', time);
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
    end
    methods(Access = protected)
        update_PrepareStim(obj);
        
        function update(obj)          
            switch obj.state
                case 'PREPARE_STIM'
                    obj.update_PrepareStim();
                case 'INIT_TRIAL'                    
                    obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
                    obj.set_param('FixationPeriodTime', ...
                        obj.taskParams.EventPeriods(1)/1000 + ...
                        rand(1)*obj.taskParams.EventPeriods(2)/1000);
            end
        end
    end
    
end


