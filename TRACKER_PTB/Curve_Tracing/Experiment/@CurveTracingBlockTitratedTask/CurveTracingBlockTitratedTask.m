classdef CurveTracingBlockTitratedTask < CurveTracingJoystickTask
    % CURVETRACINGBLOCKTITRATEDTASK Creates blocks of curve tracing trials.
    %   All trials in a block have the same target position. Target shapes
    %   are titrated to avoid bias.
    
    properties (Access = protected)
        targetLoc = nan;
    end
    methods
        function obj = CurveTracingBlockTitratedTask(commonParams, stimuliParams)
            obj = obj@CurveTracingJoystickTask(commonParams, stimuliParams);
            
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
            global Par;
            global Log;
            if obj.iTrialOfBlock == 1 || any(isnan(obj.targetLoc)) % if new block
                targetLocNames = {'UL','DL','UR','DR'};
                iTargetLoc = randi(4, 1);
                obj.targetLoc = targetLocNames{iTargetLoc};
                Log.events.add_entry(Par.lft, obj.taskName, 'BlockTargetLocSelected', obj.targetLoc);
            end
            % calculate the number of LH responses and RH responses
            % include correct and false responses
            nleft = obj.responses_hand.correct(1) + obj.responses_hand.false(1);
            nright = obj.responses_hand.correct(2) + obj.responses_hand.false(2);
            pleft = (2*obj.taskParams.maxSideProb - 1) * ...
                (nright + (1 - obj.taskParams.sideAprioriLeftProb) * ...
                            obj.taskParams.sideRespAprioriNum ) / ...
                (nleft + nright + obj.taskParams.sideRespAprioriNum) + ...
                (1 - obj.taskParams.maxSideProb);
            
            % fprintf('Probability of left response being correct: %0.1f%%\n', pleft*100);
            if rand() < pleft
                iTargetShape = 1; % make target shape the LH-shape (square)
            else
                iTargetShape = 2; % make target shape the RH-shape (diamond)
            end
            side_mask = obj.stimuli_params.iTargetShape == iTargetShape;
            
            % subset of stimuli that has target at obj.targetLoc
            stim_mask = side_mask & ...
                strcmp(obj.stimuli_params.TargetLoc, obj.targetLoc);
            mask_indices = find(stim_mask);
            stim_index = mask_indices(randi(sum(stim_mask)));
            %fprintf('Stim = %d\n', stim_index);
        end
    end
end

