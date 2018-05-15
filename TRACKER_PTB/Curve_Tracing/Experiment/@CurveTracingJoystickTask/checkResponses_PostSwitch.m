function checkResponses_PostSwitch(obj, lft)
%CHECKRESPONSES_POSTSWITCH Read new responses via DAS and check timing.
%   Detailed explanation goes here
    global Par;
    correctRespGiven = false;
    if Par.NewResponse && ...
        lft < obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(2)/1000

        % correct
        if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('iTargetShape')
            
            obj.correctResponseGiven(lft);
            correctRespGiven = true;
            
        else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('iTargetShape')

            obj.falseResponseGiven(lft)
            
        end
    elseif Par.NewResponse
        % Miss
        obj.curr_response = 'miss';
        Par.CurrResponse = Par.RESP_MISS;
        Par.ExtraWaitTime = 0;
        
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

            obj.curr_hand = Par.NewResponse; % save which hand
        Par.RespValid = false;
        Par.FalseResponseGiven=true;
        if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        end
        %Par.ResponseGiven=true;
        %Don't break trial, this would speed it up and be positive
    end
    if ~correctRespGiven
        % add current trial back into 
    end
    
    %fix_broke = strcmp(obj.curr_response, 'break_fix');
    %time1 = obj.stateStart.POSTSWITCH - obj.stateStart.PRESWITCH + obj.taskParams.EventPeriods(3)/1000;
    %time2 = obj.taskParams.EventPeriods(1)/1000 + obj.taskParams.EventPeriods(3)/1000;
    
    if isinf(obj.stateStart.SWITCHED)
        if (lft >= obj.stateStart.PRESWITCH + ...
            (obj.taskParams.EventPeriods(1) + obj.taskParams.EventPeriods(3))/1000/2)

            % switched state was not shown, show another trial in block
            obj.iTrialOfBlock = obj.iTrialOfBlock - 1;
            
            obj.updateState('TRIAL_END', lft);
            obj.goBarOrient = 1;
        end
    elseif (lft >= obj.stateStart.POSTSWITCH + obj.taskParams.EventPeriods(3)/1000 || ...
            Par.EndTrialOnResponse && ~strcmp(obj.curr_response, 'none')) && ...
            (lft >= obj.stateStart.PRESWITCH + ...
            (obj.taskParams.EventPeriods(1) + obj.taskParams.EventPeriods(3))/1000)
        
        if strcmp(obj.curr_response, 'none')==1
            obj.curr_response = 'miss';
        end
        iLoc = obj.param('iTargetLoc');
        obj.responses_loc.(obj.curr_response)(iLoc) = obj.responses_loc.(obj.curr_response)(iLoc) + 1;
        %iShape = obj.param('iTargetShape');
        if obj.curr_hand == 0
            iShape = obj.param('iTargetShape');
            obj.responses_hand.(obj.curr_response)(iShape) = ...
                obj.responses_hand.(obj.curr_response)(iShape) + 1;
        else
            obj.responses_hand.(obj.curr_response)(obj.curr_hand) = ...
                obj.responses_hand.(obj.curr_response)(obj.curr_hand) + 1;
        end
        
        obj.updateState('TRIAL_END', lft);
        obj.goBarOrient = 1;
    end
end

