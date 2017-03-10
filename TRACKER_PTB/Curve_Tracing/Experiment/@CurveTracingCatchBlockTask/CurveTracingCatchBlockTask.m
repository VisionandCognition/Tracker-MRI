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
            if obj.iTrialOfBlock == 1 || any(isnan(obj.iTargetLoc)) % if new block

                obj.iTargetLoc(1) = randi(4, 1);
                notchosen = [1:4];
                notchosen = notchosen(notchosen ~= obj.iTargetLoc(1));
                if rand() < 0.5 % make next target something other than 1
                    obj.iTargetLoc(2) = notchosen(randi(length(notchosen), 1));
                    % location 3 can be anything
                    obj.iTargetLoc(3) = randi(4, 1);
                else
                    obj.iTargetLoc(2) = obj.iTargetLoc(1);
                    % location 3 has to be different
                    obj.iTargetLoc(3) = notchosen(randi(length(notchosen), 1));
                end
            end
            % subset of stimuli that has target at obj.targetLoc
            stim_mask = strcmp(obj.stimuli_params.TargetLoc, ...
                obj.targetLocNames{obj.iTargetLoc(obj.iTrialOfBlock)});
            mask_indices = find(stim_mask);
            stim_index = mask_indices(randi(sum(stim_mask)));
        end
    end
end

