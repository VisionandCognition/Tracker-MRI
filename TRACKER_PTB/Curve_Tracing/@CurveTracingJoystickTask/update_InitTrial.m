function update_InitTrial(obj)
% Setup the stimuli information that varies per trial
global Log;
global Par;

    obj.stateStart = struct('SWITCHED', -Inf); % reset times
            
    obj.curr_response = 'none';
    obj.curr_hand = 0;
    obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
    if obj.iTrialOfBlock == 1
        obj.blockNum = obj.blockNum + 1;
    
        obj.responses_curr = struct(...
            'correct', [0], ...
            'false', [0], ...
            'miss', [0], ...
            'early', [0], ...
            'break_fix', [0]);
    end
    
    obj.curr_stim_index = obj.selectTrialStimulus();
    
    obj.readStimulusParamsForTrial(obj.curr_stim_index);
    
    Log.events.add_entry(Par.lft, obj.taskName, 'NewStimulus', num2str(obj.curr_stim_index));
    Log.events.add_entry(Par.lft, obj.taskName, 'TargetLoc', obj.param('TargetLoc'));
    
    obj.trial_log.recordTrialStimulus(obj.curr_stim);
end 