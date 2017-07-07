function correctResponseGiven(obj, lft)
    global Par
    global Log
    
    % If response has already been recorded, don't override
    %if Par.CurrResponse ~= Par.RESP_NONE
    if ~strcmp(obj.curr_response, 'none') % if curr_response is not 'none'
        return
    end

    Par.RespValid = true;
    if Par.Verbosity >= 2
        fprintf('%.0f ms\n', 1000*(lft - obj.stateStart.SWITCHED));
    end
    
    obj.curr_response = 'correct';
    Par.CurrResponse = Par.RESP_CORRECT;
    obj.curr_hand = Par.NewResponse; % save which hand
    obj.stopTrackingFixationTime(lft);

    if Par.RequireFixationForReward
        fixInRatio = obj.fixation_ratio();

        if fixInRatio >= 1.0
            RewardAmount = Par.RewardTime;
        else
            RewardAmount = Par.RewardTime * fixInRatio; %^6.7;
        end
    else
        RewardAmount = Par.RewardTime;
    end
    RewardAmount = RewardAmount * obj.taskParams.rewardMultiplier  * ...
        obj.taskParams.rewardSideRespMultiplier(obj.curr_hand);

    if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.CorrectThisTrial=true;
        
        withhold_for_release = 1.0;
        Par.GiveRewardAmount = Par.GiveRewardAmount + (1 - withhold_for_release) * RewardAmount;
        Par.GiveRewardAmount_onResponseRelease = ...
            Par.GiveRewardAmount_onResponseRelease + withhold_for_release * RewardAmount;
        Log.events.add_entry(lft, obj.taskName, 'ResponseGiven', 'CORRECT');
        %Log.events.add_entry(lft, obj.taskName, 'ResponseReward', RewardAmount);
    end
    Par.ResponseGiven=true;
    Par.CorrStreakcount=Par.CorrStreakcount+1;
end