function curve_stim_index = selectTrialStimulus(obj)
    fprintf('Selecting stim for trial %d of block.\n', obj.iTrialOfBlock);
    
    if obj.iTrialOfBlock == 0
        fprintf('Shouldn''t get here!\n')
    end
    
    if obj.iTrialOfBlock == 1 || isnan(obj.curr_stim_index) % if new block
        
        % Need to choose the first trial for this block, which
        % determine the block type.

        % not enough remaining samples
        if numel(obj.remain_stim_ind) == 0
            obj.remain_stim_ind = 1:height(obj.stimuli_params);
        end
        % choose random example from remaining
        ind = randi(length(obj.remain_stim_ind));
        obj.curr_stim_index = obj.remain_stim_ind(ind);
        curve_stim_index    = obj.remain_stim_ind(ind);

        obj.remain_stim_ind(ind) = [];
    else
        % if in the same block, reuse the same stimulus
        % For fixation task, don't need to account for side response.
        curve_stim_index = obj.curr_stim_index;
    end
    % obj.iTrialOfBlock is incremented in FixationTask!
end