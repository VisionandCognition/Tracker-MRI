classdef FullscreenCheckerboard < FixationTrackingTask & HandResponseOnSwitchTask
    % FULLSCREENCHECKERBOARD From the Retinotopy experiment
    properties
        taskName = 'Fullscreen checkerboard'
        curr_stim_index = -1;
        curr_stim = NaN;
        stimuli_params; % parameters for each individual stimulus
        stimuliParamsPath = NaN;
        
        drawChecker = true;
        state = NaN;
        currStateStart = -Inf; 
        stateStart = struct('SWITCHED', -Inf);
        ChkNum=1;
        startTrial = -Inf;
        
        iTrialOfBlock = 0;
        blockNum = 0;
        
        CheckTexture;
        TrackingCheckerContChange=false;
        tLastCheckerContChange=-Inf;
        
        trial_log = nan;
    end
    properties (Access = public)
        taskParams; % parameters that apply to every stimulus
    end
    
    methods
        function obj = FullscreenCheckerboard(commonParams, stimuliParams, taskName)
            obj.taskParams = commonParams;
            
            % Use which to search Matlab path - allows to read csv when
            % starting up tracker. Needed for Matlab 2016B.
            obj.stimuliParamsPath = which(stimuliParams);
            obj.stimuli_params = readtable(obj.stimuliParamsPath);
            if nargin >= 3
                obj.taskName = taskName;
            end
            obj.trial_log = TrialLog();
        end
        function name = name(obj)
            name = obj.taskName;
        end
        
        lft = drawStimuli(obj, lft);
        drawFix(obj);
        drawTarget(obj, color, offset, which_side, pawIndSizePix);
        drawBackgroundFixPoint(obj);
        update_PrepareStim(obj);
        
        function updateState(obj, state, time)
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
                case 'INIT_TRIAL'
                    obj.update_InitTrial();
                case 'PRESWITCH'
                    %obj.update_UpdateStimulus();
                case 'SWITCHED'
                    %obj.update_UpdateStimulus();
                case 'POSTSWITCH'
                    %obj.update_UpdateStimulus();
            end
            %obj.stateStart.(obj.state) = time;
        end
        function checkResponses(obj, lft)
            switch obj.state
                case 'PREPARE_STIM'
                case 'INIT_TRIAL'
                case 'PREFIXATION'
                    obj.checkResponses_PreFixation(lft);
                case 'PRESWITCH'
                    obj.checkResponses_PreSwitch(lft);
                case 'SWITCHED'
                    obj.checkResponses_Switched(lft);
                case 'POSTSWITCH'
                    obj.checkResponses_PostSwitch(lft);
                otherwise
                    print(obj.state)
            end
        end
        function isEnd = endOfTrial(obj)
            STR_IDENTICAL = true;
            % temporary
            isEnd = (strcmp(obj.state, 'TRIAL_END') == STR_IDENTICAL);
        end
        function isEnd = endOfBlock(obj)
            if ~obj.endOfTrial()
                isEnd = false;
            else
                isEnd = obj.iTrialOfBlock >= obj.param('BlockSize');
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
        end
        function SCNT = trackerWindowDisplay(obj)
            if strcmp(obj.taskName, 'Control CT')
                SCNT(1) = { ['Control ' num2str(obj.blockNum)] };
            else
                SCNT(1) = { ['Curve tr. ' num2str(obj.blockNum)] };
            end
            SCNT(2) = { ['C:  ' num2str(sum(obj.responses_hand.correct)) ...
                ' ' num2str(sum(obj.responses_hand.correct(1))) '+' ...
                num2str(sum(obj.responses_hand.correct(2))) ...
                ] };
            SCNT(3) = { ['F: ' num2str(sum(obj.responses_hand.false)) ...
                ' ' num2str(sum(obj.responses_hand.false(1))) '+' ...
                num2str(sum(obj.responses_hand.false(2))) ...
                ] };
            SCNT(4) = { ['M:  ' num2str(sum(obj.responses_hand.miss) + ...
                sum(obj.responses_hand.early) + sum(obj.responses_hand.break_fix))] };
            
            SCNT(5) = { ['C+F: ' num2str(...
                sum(obj.responses_hand.correct) + ...
                sum(obj.responses_hand.false)) ]};
            
            if strcmp(obj.curr_response, 'none')~=1
                SCNT(6) = { [obj.curr_response]};
            else
                SCNT(6) = {''};
            end
            SCNT(7) = { ['C/(C+F): ' num2str(...
                100*sum(obj.responses_hand.correct) / ...
                (sum(obj.responses_hand.false) + sum(obj.responses_hand.correct))) ...
                '%']};
        end
        
        function obj = set_param(obj, var, val)
            if ~isa( obj.curr_stim, 'containers.Map')
                obj.curr_stim = containers.Map;
            end
            obj.curr_stim(var) = val;
        end
    end
    methods (Access = protected)
        function stim_index = selectTrialStimulus(obj)
            stim_index = randi(size(obj.stimuli_params, 1), 1);
        end
    end
end

