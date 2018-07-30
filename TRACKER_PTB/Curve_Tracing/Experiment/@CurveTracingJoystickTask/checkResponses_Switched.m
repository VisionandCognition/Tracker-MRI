function checkResponses_Switched(obj, lft)
%CHECKRESPONSES_SWITCHED Read new responses via DAS and check timing.
%   Detailed explanation goes here
    global Par;

    if Par.NewResponse && ...
        lft >= obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(1)/1000 && ...
        lft < obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(2)/1000
        % correct
        if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('iTargetShape')
            
            obj.correctResponseGiven(lft);
            
        else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('iTargetShape')
            
            obj.falseResponseGiven(lft)
            
        end
    elseif Par.NewResponse % early or late
        % false
        Par.RespValid = false;
        if lft < obj.stateStart.SWITCHED+obj.taskParams.ResponseAllowed(2)/1000
            obj.curr_response = 'early';
            Par.CurrResponse = Par.RESP_EARLY;

            if isfield(Par, 'FeedbackSound') && isfield(Par, 'FeedbackSoundPar') && ...
                    Par.FeedbackSound(Par.CurrResponse) && ...
                    all(~isnan(Par.FeedbackSoundPar(Par.CurrResponse,:)))
                if Par.FeedbackSoundPar(Par.CurrResponse)
                    try
                        PsychPortAudio('Start', ...
                            Par.FeedbackSoundSnd(Par.CurrResponse).h, 1, 0, 1);
                    catch
                    end
                end
            end

        else
            obj.curr_response = 'miss';
            Par.CurrResponse = Par.RESP_MISS;

            if isfield(Par, 'FeedbackSound') && isfield(Par, 'FeedbackSoundPar') && ...
                    Par.FeedbackSound(Par.CurrResponse) && ...
                    all(~isnan(Par.FeedbackSoundPar(Par.CurrResponse,:)))
                if Par.FeedbackSoundPar(Par.CurrResponse)
                    try
                        PsychPortAudio('Start', ...
                            Par.FeedbackSoundSnd(Par.CurrResponse).h, 1, 0, 1);
                    catch
                    end
                end
            end

        end
        obj.curr_hand = Par.NewResponse; % save which hand
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.FalseResponseGiven=true;
    end
    
    if ~Par.FixIn && (Par.WaitForFixation && Par.WaitForFixation_phase(3)) && ...
        lft < obj.stateStart.SWITCHED+Par.ReqFixTime_PostSwitch/1000
        % false
        obj.curr_response = 'break_fix';
        Par.CurrResponse = Par.RESP_BREAK_FIX;
        Par.RespValid = false;
        if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        end
        Par.FalseResponseGiven=false;
        
        obj.stopTrackingFixationTime(lft); % might have already been called
        if Par.Verbosity >= 2
            fixInRatio = obj.fixation_ratio();
            fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f) ~ %s\n', fixInRatio, ...
                obj.time_fixating(), obj.time_not_fixating(), obj.curr_response);
        end
        
        obj.updateState('POSTSWITCH', lft);
    elseif Par.FixIn && lft < obj.stateStart.SWITCHED+Par.RewFixTime_PostSwitch(1)/1000 && ...
            lft >= obj.stateStart.SWITCHED+Par.ReqFixTime_PostSwitch/1000
        
        Par.GiveRewardAmount = Par.RewFixTime_PostSwitch(2);
        GiveRewardAuto;
        Par.AutoRewardGiven = true;
        
    elseif lft >= obj.stateStart.SWITCHED + obj.param('SwitchDur')/1000 || ...
            Par.EndTrialOnResponse && ~strcmp(obj.curr_response, 'none')
        
        obj.stopTrackingFixationTime(lft); % might have already been called
        
        if Par.Verbosity >= 2
            fixInRatio = obj.fixation_ratio();
            fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f) ~ %s\n', fixInRatio, ...
                obj.time_fixating(), obj.time_not_fixating(), obj.curr_response);
        end
    
        obj.updateState('POSTSWITCH', lft);
    end
end

