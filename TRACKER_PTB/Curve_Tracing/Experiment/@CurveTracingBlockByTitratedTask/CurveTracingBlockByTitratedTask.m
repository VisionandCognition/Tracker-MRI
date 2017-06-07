classdef CurveTracingBlockByTitratedTask < CurveTracingJoystickTask
    % CURVETRACINGBLOCKTITRATEDTASK Creates blocks of curve tracing trials.
    %   All trials in a block have the same target position. Target shapes
    %   are titrated to avoid bias.
    
    properties (Access = protected)
        targetLoc = nan;
        blockExampleIndex = nan;
        blockBy = nan;
    end
    methods
        function obj = CurveTracingBlockByTitratedTask(commonParams, stimuliParams, taskName, blockBy)
            obj = obj@CurveTracingJoystickTask(commonParams, stimuliParams, taskName);
            
            obj.blockBy = blockBy;
            
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
            % calculate the number of LH responses and RH responses
            % include correct and false responses
            nleft = obj.responses_hand.correct(1) + obj.responses_hand.false(1);
            nright = obj.responses_hand.correct(2) + obj.responses_hand.false(2);
            pleft = (2*obj.taskParams.maxSideProb - 1) * ...
                (nright + (1 - obj.taskParams.sideAprioriLeftProb) * ...
                            obj.taskParams.sideRespAprioriNum ) / ...
                (nleft + nright + obj.taskParams.sideRespAprioriNum) + ...
                (1 - obj.taskParams.maxSideProb);
            if rand() < pleft
                iTargetShape = 1; % make target shape the LH-shape (square)
            else
                iTargetShape = 2; % make target shape the RH-shape (diamond)
            end
            
            blockby_params = obj.stimuli_params.(obj.blockBy);
            
            if obj.iTrialOfBlock == 1 || isnan(obj.blockExampleIndex) % if new block
                fprintf('Pr_left: %0.0f%%\n', pleft*100);
                % choose target uniformly from target response
                side_mask = obj.stimuli_params.iTargetShape == iTargetShape;
                mask_indices = find(side_mask);
                stim_index = mask_indices(randi(sum(side_mask)));
                obj.blockExampleIndex = stim_index;
            else

                side_mask = obj.stimuli_params.iTargetShape == iTargetShape;

                % subset of stimuli that has target at obj.targetLoc
                stim_mask = side_mask & ...
                    strcmp(blockby_params, ...
                    blockby_params(obj.blockExampleIndex));
                mask_indices = find(stim_mask);
                stim_index = mask_indices(randi(sum(stim_mask)));
            end
            paramVal = blockby_params(obj.blockExampleIndex);
            paramVal = paramVal{1};
            Log.events.add_entry(Par.lft, obj.taskName, ['StimulusKey' obj.blockBy], paramVal);
        end
    end
end

