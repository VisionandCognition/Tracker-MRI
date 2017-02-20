function checkResponses_PreSwitch( obj, lft )
%CHECKRESPONSES_PRESWITCH Helper function for CheckResponses.
%   New responses are early responses during the Fixation / PreSwitch
%   State.

    global Par;

    if Par.NewResponse
        % false hit / early response
        Par.RespValid = false;
        Par.CurrResponse = Par.RESP_EARLY;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.FalseResponseGiven=true;
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
    elseif ~Par.FixIn && Par.WaitForFixation
        % false
        Par.RespValid = false;
        Par.CurrResponse = Par.RESP_BREAK_FIX;
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.FalseResponseGiven=false;
        Par.BreakTrial=true;
    end
    
    if lft >= obj.currStateStart + ...
            obj.taskParams.EventPeriods(1)/1000 + obj.param('RandomGoSwitchDelay')
        obj.goBarOrient = 2;
        obj.updateState('SWITCHED', lft);
    end
end

