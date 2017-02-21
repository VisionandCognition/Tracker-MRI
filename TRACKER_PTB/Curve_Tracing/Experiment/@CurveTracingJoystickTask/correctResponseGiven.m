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
        fixInRatio = obj.fixation_ratio();

        if fixInRatio >= 1.0
            RewardAmount = Par.GiveRewardAmount + Par.RewardTime;
        else
            RewardAmount = Par.GiveRewardAmount + Par.RewardTime * fixInRatio^6.7;
        end
    else
        RewardAmount = Par.GiveRewardAmount + Par.RewardTime;
    end

    if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.CorrectThisTrial=true;
        
        Par.GiveRewardAmount = Par.GiveRewardAmount + RewardAmount;
        Log.events.add_entry(lft, 'ResponseGiven', 'CORRECT');
        Log.events.add_entry(lft, 'ResponseReward', RewardAmount);
    end
    Par.ResponseGiven=true;
    Par.CorrStreakcount=Par.CorrStreakcount+1;
end