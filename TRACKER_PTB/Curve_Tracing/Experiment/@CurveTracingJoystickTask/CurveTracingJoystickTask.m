classdef CurveTracingJoystickTask < FixationTrackingTask
    % CURVETRACINGTASK The curve tracing task.
    properties (Access = protected)
        taskName = 'Curve tracing'
        stimuli_params; % parameters for each individual stimulus
        curr_stim_index = -1;
        curr_stim = NaN;
        state = NaN;
        currStateStart = -Inf; 
        stateStart = struct('SWITCHED', -Inf);
        goBarOrient =  1; % 1=default, 2=switched
        stimuliParamsPath = NaN;
        
        iTrialOfBlock = 0;
        blockNum = 0;
        curr_response = 'none'; % response of current trial (correct, false ...)
        curr_hand = 0; % hand that gave response of current trial
        responses_loc = struct(...
            'correct', [0 0 0 0 0], ... UpL DownL UpR DownR Center
            'false', [0 0 0 0 0], ...
            'miss', [0 0 0 0 0], ...
            'early', [0 0 0 0 0], ...
            'break_fix', [0 0 0 0 0]);
        responses_hand = struct(...
            'correct', [0 0], ... L, R
            'false', [0 0], ...
            'miss', [0 0], ...
            'early', [0 0], ...
            'break_fix', [0 0]);
        responses_curr = struct(...
            'correct', [0], ...
            'false', [0], ...
            'miss', [0], ...
            'early', [0], ...
            'break_fix', [0]);
        
        trial_log = nan;
        curves = nan;
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
        function obj = CurveTracingJoystickTask(commonParams, stimuliParams, taskName)
            % INPUT commonParams: should be a container.Map
            %       stimuliParams: should be the path to the stimuli params
            %                      in CSV format.
            obj.taskParams = commonParams;
            % Use which to search Matlab path - allows to read csv when
            % starting up tracker. Needed for Matlab 2016B.
            obj.stimuliParamsPath = which(stimuliParams);
            obj.stimuli_params = readtable(obj.stimuliParamsPath);
            if nargin >= 3
                obj.taskName = taskName;
            elseif all(strcmp(obj.stimuli_params.TargetLoc, 'Center'))
                obj.taskName = 'Control CT';
            end
            obj.trial_log = TrialLog();
        end

        lft = drawStimuli(obj, lft);
        drawTarget(obj, color, offset, which_side, pawIndSizePix);
        
        function updateState(obj, state, time)
            global Log;
            obj.state = state;
            obj.currStateStart = time;
            
            Log.events.save_next_flip();
            Log.events.add_entry(time, obj.taskName, 'DecideNewState', obj.state);
            Log.events.queue_entry(obj.taskName, 'NewState', obj.state);

            obj.update();
            obj.stateStart.(obj.state) = time;
            %fprintf('New state: %s\n', state);
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
        function write_trial_log_csv(obj, common_base_fn)
            obj.trial_log.write_csv([common_base_fn '_' obj.taskName(obj.taskName ~= ' ') '.csv'])
        end
    end
    methods (Access = protected)
        
        update_InitTrial(obj);
        update_PrepareStim(obj);
        update_PreOrPostSwitch(obj);
        
        checkResponses_PreFixation(obj, lft);
        checkResponses_PreSwitch(obj, lft);
        checkResponses_Switched(obj, lft);
        
        correctResponseGiven(obj, lft);
        falseResponseGiven(obj, lft);
        
        [pts, pts_col] = calcCurve(obj, indpos);
        readStimulusParamsForTrial(obj, stim_index);
        
        drawFix(obj);
        drawBackgroundFixPoint(obj);
        drawCurve(obj, indpos);
        drawPreSwitchFigure(obj, Par, pos, SizePix, alpha);
        
        function update(obj)
            switch obj.state
                case 'PREPARE_STIM'
                    obj.update_PrepareStim();
                case 'INIT_TRIAL'
                    obj.update_InitTrial();
                case 'PREFIXATION'
                case 'PRESWITCH'
                    obj.update_PreOrPostSwitch();
                case 'SWITCHED'
                    obj.update_PreOrPostSwitch();
                case 'POSTSWITCH'
                    %obj.update_PreOrPostSwitch();
            end
        end
        
        function stim_index = selectTrialStimulus(obj)
            stim_index = randi(size(obj.stimuli_params, 1), 1);
        end
    end
    
end
