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
        
        iTrialOfBlock = 0;
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
        
        checkResponses(obj, time);
        
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
                % if the block that just ended was the last one of block
                isEnd = obj.iTrialOfBlock >= obj.param('BlockSize');
                if isEnd
                    fprintf('End of Block\n')
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
                    % obj.update_InitSubtrial();
                    
                    fprintf('Trial %d.%d\n', obj.iTrialOfBlock, obj.iSubtrial);
                    obj.set_param('FixationPeriodTime', ...
                        obj.taskParams.EventPeriods(1)/1000 + ...
                        rand(1)*obj.taskParams.EventPeriods(2)/1000);
            end
        end
        function incrementSubtrial(obj)
            if obj.iSubtrial == 0
                fprintf('Trial %d ->', obj.iTrialOfBlock);
                obj.iTrialOfBlock = obj.iTrialOfBlock + 1;
                if obj.iTrialOfBlock > obj.param('BlockSize')
                    obj.iTrialOfBlock = 1;
                end
                fprintf(' %d\n', obj.iTrialOfBlock);
            end
            obj.curr_response = 'none';
            obj.iSubtrial = obj.iSubtrial + 1;
            % if finished with all subtrials of a trial, increment trial
            if obj.iSubtrial > obj.taskParams.subtrialsInTrial
                obj.iSubtrial = 0;
            end
        end
    end
    
end


