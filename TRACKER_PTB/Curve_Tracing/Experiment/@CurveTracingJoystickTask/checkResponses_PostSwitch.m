function checkResponses_PostSwitch(obj, lft)
%CHECKRESPONSES_POSTSWITCH Read new responses via DAS and check timing.
%   Detailed explanation goes here
    global Par;
    
    if Par.NewResponse && ...
        lft < obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(2)/1000

        % correct
        if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('iTargetShape')
            
            obj.correctResponseGiven(lft);
            
        else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('iTargetShape')

            obj.falseResponseGiven(lft)
            
        end
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
    elseif Par.NewResponse
        % Miss
        obj.curr_response = 'miss';
        Par.CurrResponse = Par.RESP_MISS;
        Par.RespValid = false;
        Par.FalseResponseGiven=true;
        if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        end
        %Par.ResponseGiven=true;
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
        %Don't break trial, this would speed it up and be positive
    end
    
    %fix_broke = strcmp(obj.curr_response, 'break_fix');
    time1 = obj.stateStart.POSTSWITCH - obj.stateStart.PRESWITCH + obj.taskParams.EventPeriods(3)/1000;
    time2 = obj.taskParams.EventPeriods(1)/1000 + obj.taskParams.EventPeriods(3)/1000;
    if (lft >= obj.stateStart.POSTSWITCH + obj.taskParams.EventPeriods(3)/1000 || ...
            Par.EndTrialOnResponse && ~strcmp(obj.curr_response, 'none')) && ...
            (lft >= obj.stateStart.PRESWITCH + ...
            obj.taskParams.EventPeriods(1)/1000 + obj.taskParams.EventPeriods(3)/1000)
        
        if strcmp(obj.curr_response, 'none')==1
            obj.curr_response = 'miss';
        end
        iLoc = obj.param('iTargetLoc');
        obj.responses_loc.(obj.curr_response)(iLoc) = obj.responses_loc.(obj.curr_response)(iLoc) + 1;
        iShape = obj.param('iTargetShape');
        obj.responses_shape.(obj.curr_response)(iShape) = obj.responses_shape.(obj.curr_response)(iShape) + 1;
        
        obj.updateState('TRIAL_END', lft);
        
        obj.goBarOrient = 1;
    end
end

