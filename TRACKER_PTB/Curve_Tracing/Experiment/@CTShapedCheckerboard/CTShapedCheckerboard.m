classdef CTShapedCheckerboard < FullscreenCheckerboard
    %CTSHAPEDCHECKERBOARD The fullscreen checkerboard masked to just the
    % areas of the Curve Tracing Stimuli.
    
    properties
        curves = nan;
        %maskedCB = nan; % checkboard with masks applied
        maskedCBTexture = nan; % all the checkerboard patterns

        % The stimuli_params are used by the Fullscreen Checkerboard
        % for the center target. The following are for the stimuli outside
        % of the center target. They have "curve" in the name, because the
        % stimuli outside of the target contain curves, although it also
        % includes the target shapes.
        %   stimuli_params; % parameters for each individual stimulus
        curveStimuliParamsPath = NaN;
        curr_stim_index = NaN; % indexes stimuli_params
        %   curr_stim = NaN; % parameters for the stimulus of the current trial

        remain_stim_ind = []; % remaining stimuli indices for sampling
    end

    methods
        function obj = CTShapedCheckerboard(commonParams, ...
                curveStimParams, ...
                taskName)
            if nargin < 3
                taskName = 'CT-Shaped Checkerboard';
            end
            obj = obj@FullscreenCheckerboard(commonParams, taskName);
            
            obj.curveStimuliParamsPath = which(curveStimParams);
            obj.stimuli_params = readtable(obj.curveStimuliParamsPath);
        end

        function [val, status] = param(obj, var, varargin)
            try
                val = obj.curr_stim(var);
                status = true;
            catch ME
                % Only catch errors due to the key not being found
                if ~strcmp(ME.identifier, 'MATLAB:Containers:Map:NoKey') && ...
                        ~strcmp(ME.identifier, 'MATLAB:badsubscript')
                    rethrow(ME);
                end
                
                % This will check for the parameters in curr_stim and then
                % taskParams.
                [val, status] = param@FullscreenCheckerboard(obj, var, varargin{:});
            end
            if nargout < 2 && ~status
                % if calling function doesn't get the status value and
                %   it is false, throw an error.
                error('Parameter variable %s does not exist!', var);
            end
        end

        function updateState(obj, state, time)
            global Log;
            obj.state = state;
            
            obj.currStateStart = time;
            obj.stateStart.(obj.state) = time;
            
            Log.events.save_next_flip();
            Log.events.add_entry(time, obj.taskName, 'DecideNewState', obj.state);
            Log.events.queue_entry(obj.taskName, 'NewState', obj.state);

            switch obj.state
                case 'PREPARE_STIM'
                    obj.update_PrepareStim();
                case 'INIT_TRIAL'
                    obj.update_InitTrial();
            end
        end
        function write_trial_log_csv(obj, common_base_fn)
            obj.trial_log.write_csv([common_base_fn '_' obj.taskName(obj.taskName ~= ' ') '.csv'])
            obj.write_param_csv(common_base_fn)
        end
        function write_param_csv(obj, common_base_fn)
            % This function ignored in FullscreenCheckerboard, the
            % superclass
            writetable(obj.stimuli_params, [fileparts(common_base_fn) '/' obj.taskName '.stimulus-params.csv'])
        end
        
        lft = drawStimuli(obj, lft);
    end
    
    methods (Access = protected)
        update_PrepareStim(obj);
        [pts, pts_col] = calcCurve(obj, indpos);
        
        stim_index = selectTrialStimulus(obj);
    end
end