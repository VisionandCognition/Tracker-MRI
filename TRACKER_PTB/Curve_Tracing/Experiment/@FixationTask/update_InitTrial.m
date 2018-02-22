function update_InitTrial(obj)
    fprintf('FixationTask:update_InitTrial(%s)\n', obj.state);
    
    if obj.iSubtrial == 0  % iSubtrial and iTrialOfBlock should be positive
        obj.incrementSubtrial();
    end
end 