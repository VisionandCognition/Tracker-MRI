function update_InitTrial(obj)
% Setup the stimuli information that varies per trial
global Par;
global Log;

    obj.stateStart = struct('SWITCHED', -Inf); % reset times
            
    obj.curr_response = 'none';
    obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
    if obj.iTrialOfBlock == 1
        obj.blockNum = obj.blockNum + 1;
    end
    
    obj.curr_stim_index = obj.selectTrialStimulus(); %randi(size(obj.stimuli_params, 1), 1);
    
    obj.readStimulusParams(obj.curr_stim_index);
    
    Log.events.add_entry(nan, obj.taskName, 'NewStimulus', obj.curr_stim_index);
    Log.events.add_entry(nan, obj.taskName, 'TargetLoc', obj.param('TargetLoc'));
    
    obj.trial_log.recordTrialStimulus(obj.curr_stim);
end 