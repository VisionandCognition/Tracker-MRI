function checkResponses_PreSwitch( obj, lft )
%CHECKRESPONSES_PRESWITCH Helper function for CheckResponses.
%   New responses are early responses during the Fixation / PreSwitch
%   State.

    global Par;

    if Par.NewResponse
        % false hit / early response
        Par.RespValid = false;
        obj.curr_response = 'early';
        Par.CurrResponse = Par.RESP_EARLY;
        % count the number of this type of responses
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        obj.curr_hand = Par.NewResponse; % save which hand
        Par.FalseResponseGiven=true;
        
        if Par.EndTrialOnResponse
            obj.updateState('POSTSWITCH', lft);
        end
    elseif ~Par.FixIn && Par.WaitForFixation
        Par.RespValid = false;
        obj.curr_response = 'break_fix';
        Par.CurrResponse = Par.RESP_BREAK_FIX;
        obj.curr_hand = Par.NewResponse; % save which hand
        % count the number of this type of responses
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.FalseResponseGiven=false;
        
        obj.updateState('POSTSWITCH', lft);
    elseif ~Par.HandsInPosition && Par.RequireHandsIn
        Par.RespValid = false;
        obj.curr_response = 'remove_hand';
        Par.CurrResponse = Par.RESP_REMOVE_HAND;
        obj.curr_hand = Par.NewResponse; % save which hand
        % count the number of this type of responses
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.FalseResponseGiven=false;
        
        obj.updateState('POSTSWITCH', lft);
    end
    
    if lft >= obj.currStateStart + ...
            obj.taskParams.EventPeriods(1)/1000 + obj.param('RandomGoSwitchDelay')

        obj.goBarOrient = 2;
        obj.updateState('SWITCHED', lft);
    end
end
