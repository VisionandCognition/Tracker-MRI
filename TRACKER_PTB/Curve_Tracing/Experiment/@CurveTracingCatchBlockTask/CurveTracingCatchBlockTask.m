classdef CurveTracingCatchBlockTask < CurveTracingJoystickTask
    % CURVETRACINGCATCHBLOCKTASK Creates blocks of curve tracing trials.
    %   One or more of the trials is a mismatch
    properties (Constant)
        targetLocNames = {'UL','DL','UR','DR'};
    end
    properties (Access = protected)
        iTargetLoc = [nan nan nan]
    end
    methods
        function obj = CurveTracingCatchBlockTask(commonParams, stimuliParams)
            obj = obj@CurveTracingJoystickTask(commonParams, stimuliParams);
            obj.taskName = 'Catch CT';
        end
    end
    
    methods (Access = protected)
        function stim_index = selectTrialStimulus(obj)
            % only act different from super when last trial of block
            if obj.iTrialOfBlock < obj.param('BlockSize') || any(isnan(obj.iTargetLoc))
                stim_index = selectTrialStimulus@CurveTracingJoystickTask(...
                    obj);
                return
            end
            % subset of stimuli that has target at obj.targetLoc
            paramval = obj.stimuli_params(obj.block_example_ind,:).(obj.sampleBy){1};

            % invert previous
            stim_mask = ~strcmp( ...
                obj.stimuli_params.(obj.sampleBy), ...
                paramval);
            dbstop;
            
            mask_indices = find(stim_mask);
            ind = randi(numel(mask_indices));
            stim_index = mask_indices(ind);
        end
    end
end

