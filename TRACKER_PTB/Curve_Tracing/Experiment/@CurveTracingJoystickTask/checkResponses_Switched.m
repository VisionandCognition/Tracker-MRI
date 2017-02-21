function checkResponses_Switched(obj, lft)
%CHECKRESPONSES_SWITCHED Read new responses via DAS and check timing.
%   Detailed explanation goes here
    global Par;

    if Par.NewResponse && ...
        lft >= obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(1)/1000 && ...
        lft < obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(2)/1000
        % correct
        if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('Target')
            
            obj.correctResponseGiven(lft);
            
        else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('Target')
            
            obj.falseResponseGiven(lft)
            
        end
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
    elseif Par.NewResponse % early or late
        % false
        Par.RespValid = false;
        if lft < obj.stateStart.SWITCHED+obj.taskParams.ResponseAllowed(2)/1000
            Par.CurrResponse = Par.RESP_EARLY;
        else
            Par.CurrResponse = Par.RESP_MISS;
        end
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        Par.FalseResponseGiven=true;
        Par.RespTimes=[Par.RespTimes;
            lft-Par.ExpStart Par.RespValid];
    elseif ~Par.FixIn && Par.WaitForFixation
        % false
        Par.CurrResponse = Par.RESP_BREAK_FIX;
        Par.RespValid = false;
        if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
            Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
            %Par.ResponsePos
            Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        end
        Par.FalseResponseGiven=false;
        Par.BreakTrial=true;
    end
    
    if lft >= obj.stateStart.SWITCHED + obj.param('SwitchDur')/1000
        
        obj.stopTrackingFixationTime(lft); % might have already been called
        fixInRatio = obj.fixation_ratio();
        fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f)\n', fixInRatio, ...
            obj.time_fixating(), obj.time_not_fixating());
    
        obj.updateState('POSTSWITCH', lft);
        obj.goBarOrient = 1;
    end
    %        ~Par.PosReset && ~Par.ESC && ~Par.BreakTrial && ...
    %        (Par.CurrResponse ~= Par.RESP_CORRECT)
end

