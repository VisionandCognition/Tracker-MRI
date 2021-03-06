function update_InitTrial(obj)
    fprintf('CTShapedCheckerboard:update_InitTrial(%s)\n', obj.state);
    
    update_InitTrial@FixationTask(obj);
% Setup the stimuli information that varies per trial
global Log;
global Par;
    % ===== setup the stimulus outside of the fixation point
            
    obj.curr_stim_index = obj.selectTrialStimulus();
    obj.readStimulusParamsForTrial(obj.curr_stim_index);

    Log.events.add_entry(Par.lft, obj.taskName, 'NewStimulus', num2str(obj.curr_stim_index));
    Log.events.add_entry(Par.lft, obj.taskName, 'CombinedStim', obj.param('CombinedStim'));
    fprintf('\t%s\n', obj.param('CombinedStim'))
    
    obj.trial_log.recordTrialStimulus(obj.curr_stim);
end 