classdef FullscreenCheckerboard < FixationTask
    % FULLSCREENCHECKERBOARD From the Retinotopy experiment
    properties (Access = protected)
        % curr_stim_index = -1; % should be moved to CTShapedCheckerboard
        
        drawChecker = true;
        ChkNum=1;
        startTrial = -Inf;
        
        CheckTexture;
        TrackingCheckerContChange=false;
        tLastCheckerContChange=-Inf;
        
        trial_log = nan;
        
        CB1 = nan;
        CB2 = nan;
    end
    
    methods
        function obj = FullscreenCheckerboard(commonParams, taskName)
            obj = obj@FixationTask(commonParams);
            
            if nargin >= 2
                obj.taskName = taskName;
            else
                obj.taskName = 'Fullscreen checkerboard';
            end
            
            obj.trial_log = TrialLog();
        end
        function name = name(obj)
            name = obj.taskName;
        end
        
        lft = drawStimuli(obj, lft);
        
        
        function updateState(obj, state, time)
            fprintf('FullscreenCheckerboard:updateState(%s)\n', state);
            global Log;
            obj.state = state;
            
            obj.currStateStart = time;
            obj.stateStart.(obj.state) = time;
            
            Log.events.save_next_flip();
            Log.events.add_entry(time, obj.taskName, 'DecideNewState', obj.state);
            Log.events.queue_entry(obj.taskName, 'NewState', obj.state);

            switch obj.state
                case 'PREPARE_STIM' % only called once, at beginning
                    obj.update_PrepareStim();
            end
        end
        function [val, status] = param(obj, var, default_value)
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
                    if nargin >= 3
                        val = default_value;
                        status = true;
                    else
                        val = nan;
                        status = false;
                    end
                end
            end
            if nargout < 2 && ~status
                % if calling function doesn't get the status value and
                %   it is false, throw an error.
                error('Parameter variable %s does not exist!', var);
            end
        end
        
        function write_trial_log_csv(obj, common_base_fn)
            obj.trial_log.write_csv([common_base_fn '_' obj.taskName(obj.taskName ~= ' ') '.csv'])
            obj.write_param_csv(common_base_fn)
        end
        function write_param_csv(obj, common_base_fn)
            % Nothing to write, there is no stimuli_params for full screeen
            % checkerboard.
            %writetable(obj.stimuli_params, [common_base_fn '.stimulus-params.csv'])
        end
        
        function obj = set_param(obj, var, val)
            if ~isa( obj.curr_stim, 'containers.Map')
                obj.curr_stim = containers.Map;
            end
            obj.curr_stim(var) = val;
        end
    end
    methods (Access = protected)
        
        update_PrepareStim(obj);
        
        function stim_index = selectTrialStimulus(obj)
            stim_index = randi(size(obj.stimuli_params, 1), 1);
        end
    end
end

