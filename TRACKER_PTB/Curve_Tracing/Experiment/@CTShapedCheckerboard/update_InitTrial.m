function update_InitTrial(obj)
% Setup the stimuli information that varies per trial
global Log;
global Par;
    % setups up the trial information for the true / center target
    update_InitTrial@FullscreenCheckerboard(obj);

    % ===== setup the stimulus outside of the fixation point
            
    obj.curr_response = 'none';
    obj.curr_hand = 0;
    %obj.iTrialOfBlock is updated by FullscreenCheckerboard
    %obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
    if obj.iTrialOfBlock == 1
        obj.blockNum = obj.blockNum + 1;
    
        obj.responses_curr = struct(...
            'correct', [0], ...
            'false', [0], ...
            'miss', [0], ...
            'early', [0], ...
            'break_fix', [0]);
        
        % only update the curve stimulus once every block
        obj.curr_curve_stim_index = randi(size(obj.curve_stimuli_params, 1), 1);
    end
    if obj.curr_curve_stim_index < 1
        obj.curr_curve_stim_index = randi(size(obj.curve_stimuli_params, 1), 1);
    end
    
    obj.curr_curve_stim = containers.Map(...
        obj.curve_stimuli_params.Properties.VariableNames, ...
        table2cell(obj.curve_stimuli_params(obj.curr_curve_stim_index, :)));
    
    % read parameters for the center target
    obj.readStimulusParamsForTrial(obj.curr_stim_index);
    
    Log.events.add_entry(Par.lft, obj.taskName, 'NewStimulus', num2str(obj.curr_stim_index));
    Log.events.add_entry(Par.lft, obj.taskName, 'TargetLoc', obj.param('TargetLoc'));
    
    obj.trial_log.recordTrialStimulus(obj.curr_stim);
end 