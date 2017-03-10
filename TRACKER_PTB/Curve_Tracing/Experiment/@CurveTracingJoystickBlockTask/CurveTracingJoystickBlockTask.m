classdef CurveTracingJoystickBlockTask < CurveTracingJoystickTask
    % CURVETRACINGJOYSTICKBLOCKTASK Creates blocks of curve tracing trials.
    %   Trials in a block are all the same location.
    
    properties (Access = protected)
        targetLoc = nan;
    end
    methods
        function obj = CurveTracingJoystickBlockTask(commonParams, stimuliParams)
            obj = obj@CurveTracingJoystickTask(commonParams, stimuliParams);
        end
    end
    
    methods (Access = protected)
        function stim_index = selectTrialStimulus(obj)
            if obj.iTrialOfBlock == 1 || any(isnan(obj.targetLoc)) % if new block
                targetLocNames = {'UL','DL','UR','DR'};
                iTargetLoc = randi(4, 1);
                obj.targetLoc = targetLocNames{iTargetLoc};
            end
            % subset of stimuli that has target at obj.targetLoc
            stim_mask = strcmp(obj.stimuli_params.TargetLoc, obj.targetLoc);
            mask_indices = find(stim_mask);
            stim_index = mask_indices(randi(sum(stim_mask)));
            %fprintf('Stim = %d\n', stim_index);
        end
    end
end

