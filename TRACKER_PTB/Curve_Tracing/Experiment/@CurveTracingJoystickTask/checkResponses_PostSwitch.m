function checkResponses_PostSwitch(obj, lft)
%CHECKRESPONSES_POSTSWITCH Read new responses via DAS and check timing.
%   Detailed explanation goes here
    global Par;
    
    if Par.NewResponse && ...
        lft < obj.stateStart.SWITCHED+obj.taskParams.ResponseAllowed(2)/1000

        % correct
        if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('Target')
            
            obj.correctResponseGiven(lft);
            
        else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('Target')

            obj.falseResponseGiven(lft)
            
        end
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
    elseif Par.NewResponse
        % Miss
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
    
    if lft >= obj.stateStart.POSTSWITCH + Stm(1).task.taskParams.EventPeriods(3)/1000 
        obj.updateState('TRIAL_END', lft);
    end
end

