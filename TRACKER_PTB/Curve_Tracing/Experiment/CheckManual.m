function CheckManual(Stm)
% check DAS for manual responses

global Par;
global Log;

    %check the incoming signal on DAS channel #3  (#4 base 1)
    % NB dasgetlevel only starts counting at the third channel (#2)
    ChanLevels=dasgetlevel;
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
        if Par.HandIsIn(1)
            Par.HandIsIn(1)=false;
            Log.events.add_entry(GetSecs, NaN, 'Response_Release', 'Left');
            if ~any(Par.HandIsIn)
                ResponsesReleased();
            end
        end
    else
        Par.BeamLIsBlocked = true;
        if ~Par.HandIsIn(1)
            Par.HandIsIn(1)=true;
            Log.events.add_entry(GetSecs, NaN, 'Response_Initiate', 'Left');
        end
    end
    assert(Stm(1).task.taskParams.NumBeams >= 2)
    
    %check the incoming signal on DAS channel #4 (#5 base 1)
    % NB dasgetlevel only starts counting at the third channel (#2)
    % Right / Secondary beam
    Log.RespSignal = ChanLevels(5-2);
    if strcmp(computer,'PCWIN64') && Log.RespSignal > 40000 || ... 64bit das card
            strcmp(computer,'PCWIN') && Log.RespSignal > 2750 || ... % old das card
            Par.TestRunstimWithoutDAS

        Par.BeamRIsBlocked = false;
        if Par.HandIsIn(2)
            Par.HandIsIn(2)=false;
            Log.events.add_entry(GetSecs, NaN, 'Response_Release', 'Right');
            if ~any(Par.HandIsIn)
                ResponsesReleased();
            end
        end
    else
        Par.BeamRIsBlocked = true;
        if ~Par.HandIsIn(2)
            Par.HandIsIn(2)=true;
            Log.events.add_entry(GetSecs, NaN, 'Response_Initiate', 'Right');
        end
    end
    
    Par.NewResponse = false;
    
    if Par.ForpRespLeft
        Par.BeamLIsBlocked = true;
        Par.HandIsIn(1) = true;
        Par.ForpRespLeft = false;
        Par.NewResponse = 1;
        % logged in CheckKeys
    elseif Par.ForpRespRight
        Par.BeamRIsBlocked = true;
        Par.HandIsIn(2) = true;
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

    Par.GoNewTrial = ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked;

    function ResponsesReleased
        Par.GiveRewardAmount = Par.GiveRewardAmount + Par.GiveRewardAmount_onResponseRelease;
        Par.GiveRewardAmount_onResponseRelease = 0;
        GiveRewardAuto; % make sure reward immediately on release
    end
end