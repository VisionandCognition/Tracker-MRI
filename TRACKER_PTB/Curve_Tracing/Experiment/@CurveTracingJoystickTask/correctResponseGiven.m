function correctResponseGiven(obj, lft)
    global Par
    global Log
    
    if Par.CurrResponse ~= Par.RESP_NONE
        return
    end

    Par.RespValid = true;
    Par.CurrResponse = Par.RESP_CORRECT;
    obj.stopTrackingFixationTime(lft);
    RewardAmount = 0;

    if Par.RequireFixationForReward
        % Check obj.trialFixS / (obj.trialFixS + obj.trialNoFixS);
        fixInRatio = obj.trialFixS / (obj.trialNoFixS + obj.trialFixS);
        fprintf('Fixation ratio: %0.2f\n', fixInRatio);
        thresh = 1.0;
        if fixInRatio >= thresh
            RewardAmount = Par.GiveRewardAmount + Par.RewardTime;
        end
    else
        RewardAmount = Par.GiveRewardAmount + Par.RewardTime;
    end

    if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrectThisTrial=true;
        
        Par.GiveRewardAmount = Par.GiveRewardAmount + RewardAmount;
        Log.Events.add_entry(lft, 'ResponseGiven', 'CORRECT');
        Log.Events.add_entry(lft, 'ResponseReward', RewardAmount);
    end
    Par.ResponseGiven=true;
    Par.CorrStreakcount=Par.CorrStreakcount+1;
end