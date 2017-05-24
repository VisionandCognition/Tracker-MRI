classdef CurveTracingTitratedTask < CurveTracingJoystickTask
    % CURVETRACINGTITRATEDTASK Creates curve tracing trials.
    %   Target locations are completely random each trial.
    %   Target shapes are titrated to avoid bias.
    
    properties (Access = protected)
        targetLoc = nan;
    end
    methods
        function obj = CurveTracingTitratedTask(commonParams, stimuliParams, taskName)
            obj = obj@CurveTracingJoystickTask(commonParams, stimuliParams, taskName);
            
            assert(isfield(commonParams, 'sideRespAprioriNum'), ...
                ['Parameter sideRespAprioriNum must be defined for ' ...
                class(obj)]);
            assert(commonParams.sideRespAprioriNum > 0);
            assert(isfield(commonParams, 'maxSideProb'), ...
                ['Parameter maxSideProb must be defined for ' ...
                class(obj)]);
            assert(commonParams.maxSideProb >= 0.5 && ...
                commonParams.maxSideProb <= 1.0);
        end
    end
    
    methods (Access = protected)
        function stim_index = selectTrialStimulus(obj)
            % calculate the number of LH responses and RH responses
            % include correct and false responses
            nleft = obj.responses_hand.correct(1) + obj.responses_hand.false(1);
            nright = obj.responses_hand.correct(2) + obj.responses_hand.false(2);
            pleft = (2*obj.taskParams.maxSideProb - 1) * ...
                (nright + (1 - obj.taskParams.sideAprioriLeftProb) * ...
                            obj.taskParams.sideRespAprioriNum ) / ...
                (nleft + nright + obj.taskParams.sideRespAprioriNum) + ...
                (1 - obj.taskParams.maxSideProb);
            fprintf('Probability of left response being correct: %0.1f%%\n', pleft*100);
            if rand() < pleft
                iTargetShape = 1; % make target shape the LH-shape (square)
            else
                iTargetShape = 2; % make target shape the RH-shape (diamond)
            end
            side_mask = obj.stimuli_params.iTargetShape == iTargetShape;
            
            mask_indices = find(side_mask);
            stim_index = mask_indices(randi(sum(side_mask)));
        end
    end
end

