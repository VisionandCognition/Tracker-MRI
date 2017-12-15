function CheckManual(Stm)
% check DAS for manual responses

global Par;
global Log;

    ChanLevels=dasgetlevel;
    
    % -------------------------------------- Left Side Response
    
    %check the incoming signal on DAS channel #3  (#4 base 1)
    % NB dasgetlevel only starts counting at the third channel (#2)
    Log.RespSignal = ChanLevels(4-2);
    % dasgetlevel starts reporting at channel 3, so subtract 2 from the channel you want (1 based)

    % it's a slightly noisy signal
    % on 32 bit windows
    % 3770-3800 means uninterrupted light beam
    % 2080-2090 means interrupted light beam
    % to be safe: take the cut-off halfway @2750
    % values are different for 64 bit windows
    if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 || ... 64bit das card
            strcmp(computer,'PCWIN') && Log.RespSignal > 2750 || ... % old das card
            Par.TestRunstimWithoutDAS
        Par.BeamLIsBlocked = false;
        if Par.HandResponse(1)
            Par.HandResponse(1)=false;
            Log.events.add_entry(GetSecs, NaN, 'Response_Release', 'Left');
            if ~any(Par.HandResponse)
                ResponsesReleased();
            end
        end
    else
        Par.BeamLIsBlocked = true;
        if ~Par.HandResponse(1)
            Par.HandResponse(1)=true;
            Log.events.add_entry(GetSecs, NaN, 'Response_Initiate', 'Left');
        end
    end
    
    
    % -------------------------------------- Right Side Response
    assert(Stm(1).task.taskParams.NumBeams >= 2)
    
    %check the incoming signal on DAS channel #4 (#5 base 1)
    % NB dasgetlevel only starts counting at the third channel (#2)
    % Right / Secondary beam
    Log.RespSignal = ChanLevels(5-2);
    if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 || ... 64bit das card
            strcmp(computer,'PCWIN') && Log.RespSignal > 2750 || ... % old das card
            Par.TestRunstimWithoutDAS

        Par.BeamRIsBlocked = false;
        if Par.HandResponse(2)
            Par.HandResponse(2)=false;
            Log.events.add_entry(GetSecs, NaN, 'Response_Release', 'Right');
            if ~any(Par.HandResponse)
                ResponsesReleased();
            end
        end
    else
        Par.BeamRIsBlocked = true;
        if ~Par.HandResponse(2)
            Par.HandResponse(2)=true;
            Log.events.add_entry(GetSecs, NaN, 'Response_Initiate', 'Right');
        end
    end
    
    Par.NewResponse = false;
    
    if Par.ForpRespLeft
        Par.BeamLIsBlocked = true;
        Par.HandResponse(1) = true;
        Par.ForpRespLeft = false;
        Par.NewResponse = 1;
        % logged in CheckKeys
    elseif Par.ForpRespRight
        Par.BeamRIsBlocked = true;
        Par.HandResponse(2) = true;
        Par.ForpRespRight = false;
        Par.NewResponse = 2;
        % logged in CheckKeys
    end

    % interpret left side
    if Par.BeamLIsBlocked && ~Par.BeamLWasBlocked
        Par.NewResponse = 1;
        Par.BeamLWasBlocked = true;
    elseif ~Par.BeamLIsBlocked && Par.BeamLWasBlocked
        % key is released
        Par.BeamLWasBlocked = false;
    end

    % interpret right side
    if Par.BeamRIsBlocked && ~Par.BeamRWasBlocked
        Par.NewResponse = 2;
        Par.BeamRWasBlocked = true;
    elseif ~Par.BeamRIsBlocked && Par.BeamRWasBlocked
        % key is released
        Par.BeamRWasBlocked = false;
    end

    if Par.NewResponse
        Par.TrialResponse = Par.NewResponse;
    end
    
    % -------------------------------------- Hands ready to respond
    
    %check the incoming signal on DAS channel #6  (#7 base 1)
    % NB dasgetlevel only starts counting at the third channel (#2)
    HandInSignals = ChanLevels((6:7)-1);
    % dasgetlevel starts reporting at channel 3, so subtract 2 from the channel you want (1 based)

    % it's a slightly noisy signal
    % on 32 bit windows
    % 3770-3800 means uninterrupted light beam
    % 2080-2090 means interrupted light beam
    % to be safe: take the cut-off halfway @2750
    % values are different for 64 bit windows
    if strcmp(computer,'PCWIN64')
        HandsInNow = HandInSignals < 40000;
    else
        HandsInNow = HandInSignals < 2750;
    end
    
    hand = {'Left', 'Right'};
    hand_pos_changed = false;
    for i = 1:2
        if HandsInNow(i) && ~Par.HandsIn(i)
            Log.events.add_entry(GetSecs, NaN, 'Hand_Inserted', hand{i});
            hand_pos_changed = true;
            
        elseif ~HandsInNow(i) && Par.HandsIn(i)
            Log.events.add_entry(GetSecs, NaN, 'Hand_Removed', hand{i});
            hand_pos_changed = true;
        end
    end
    
    % Reward for putting hand in, even if not "required"
    now = GetSecs;
    if sum(HandsInNow) > sum(Par.HandsIn)  % Par.RequireHandsIn && 
        % A hand(s) was put in box
        switch(sum(HandsInNow))
            case 1
                if now - Par.SingleHandInTime > Par.MinSecsBetweenSingleHandInRewards
                    Par.GiveRewardAmount = Par.GiveRewardAmount + Par.SingleHandInReward;
                    GiveRewardAuto;
                end
            case 2
                if now - Par.BothHandsInTime > Par.MinSecsBetweenBothHandsInRewards
                    Par.GiveRewardAmount = Par.GiveRewardAmount + Par.BothHandsInReward;
                    GiveRewardAuto;
                end
        end
    end
    if sum(HandsInNow) >= 1
        Par.SingleHandInTime = now;
    end
    if sum(HandsInNow) >= 2
        Par.BothHandsInTime = now;
    end
    Par.HandsIn = HandsInNow;
    if hand_pos_changed
        fprintf('Hand position: [ ');
        if Par.HandsIn(1)
            fprintf('IN, ')
        else
            fprintf('--, ')
        end
        if Par.HandsIn(2)
            fprintf('IN ]\n')
        else
            fprintf('-- ]\n')
        end
        fprintf('\t\t\t%d %d\n', HandInSignals);
    end
    Par.HandsInPosition = all(Par.HandsIn);
    Par.GoNewTrial = ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked && ...
        (Par.HandsInPosition || ~Par.RequireHandsIn);

    function ResponsesReleased
        Par.GiveRewardAmount = Par.GiveRewardAmount + Par.GiveRewardAmount_onResponseRelease;
        Par.GiveRewardAmount_onResponseRelease = 0;
        GiveRewardAuto; % make sure reward immediately on release
    end
end