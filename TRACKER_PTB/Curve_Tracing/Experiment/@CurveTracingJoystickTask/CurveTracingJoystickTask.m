classdef CurveTracingJoystickTask < handle
    % CurveTracingTask The curve tracing task.
    properties (Constant)
        taskName = 'Curve tracing'
    end
    properties (Access = private)
        stimuli_params; % parameters for each individual stimulus
        curr_stim_index = -1;
        curr_stim = NaN;
        state = NaN;
        currStateStart = -Inf; 
        stateStart = struct('SWITCHED', -Inf);
    end
    properties (Access = public)
        taskParams; % parameters that apply to every stimulus
    end
    methods (Access = private)
        update_InitTrial(obj);
        update_PrepareStim(obj);
        update_PreOrPostSwitch(obj);
        
        checkResponses_PreSwitch(obj, lft);
        checkResponses_Switched(obj, lft);
    end
    methods
        function obj = CurveTracingJoystickTask(commonParams, stimuliParams)
            % INPUT commonParams: should be a container.Map
            %       stimuliParams: should be the path to the stimuli params
            %                      in CSV format.
            obj.taskParams = commonParams;
            obj.stimuli_params = readtable(stimuliParams);
        end
        
        drawFix(obj);
        drawBackgroundFixPoint(obj);
        drawCurve(obj, pos, connection1, connection2, indpos, Par, Stm);
        drawPreSwitchFigure(obj, Par, pos, SizePix, alpha);
        lft = drawStimuli(obj, lft);
        drawTarget(obj, color, offset, which_side);
        
        function updateState(obj, State, time)
            obj.state = State;
            if nargin > 2
                obj.currStateStart = time;
                
                if strcmp(obj.state, 'SWITCHED')==1
                    obj.stateStart.SWITCHED = time;
                end
            end
            % fprintf('New state: %s\n', State);
        end
        
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
                    obj.update_PreOrPostSwitch();
                otherwise
                    print(obj.state)
            end
        end
        function checkResponses(obj, lft)
            switch obj.state
                case 'PREPARE_STIM'
                case 'INIT_TRIAL'
                case 'PREFIXATION'
                case 'PRESWITCH'
                    obj.checkResponses_PreSwitch(lft);
                case 'SWITCHED'
                    obj.checkResponses_Switched(lft);
                case 'POSTSWITCH'
                    obj.checkResponses_Switched(lft);
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
    end
    methods(Static)
    end
    
end
