function checkResponses_Switched(obj, lft)
%CHECKRESPONSES Read new responses via DAS.
%   Detailed explanation goes here

    global Par;
    STR_IDENTICAL = 1;

    if strcmp(obj.state, 'SWITCHED') == STR_IDENTICAL
        if Par.NewResponse && ...
            lft >= obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(1)/1000 && ...
            lft < obj.stateStart.SWITCHED + obj.taskParams.ResponseAllowed(2)/1000
            % correct
            if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('Target')
                Par.RespValid = true;
                Par.CurrResponse = Par.RESP_CORRECT;
                Par.GiveRewardAmount = Par.GiveRewardAmount + Par.RewardTime;
                
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    Par.CorrectThisTrial = true;
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('Target')
                % false
                Par.RespValid = false;
                Par.CurrResponse = Par.RESP_FALSE;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                end
                Par.FalseResponseGiven=true;
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
        elseif ~Par.FixIn && Par.RequireFixation
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
    elseif strcmp(obj.state, 'POSTSWITCH') == STR_IDENTICAL
        if Par.NewResponse && ...
            lft < obj.stateStart.SWITCHED+obj.taskParams.ResponseAllowed(2)/1000
            
            % correct
            if ~obj.param('RequireSpecificPaw') || Par.NewResponse == obj.param('Target')
                Par.RespValid = true;
                Par.CurrResponse = Par.RESP_CORRECT;
                Par.GiveRewardAmount = Par.GiveRewardAmount + Par.RewardTime;
                
                if ~Par.ResponseGiven  && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                    Par.CorrectThisTrial=true;
                end
                Par.ResponseGiven=true;
                Par.CorrStreakcount=Par.CorrStreakcount+1;
            else %if ~obj.param('RequireSpecificPaw') || Par.NewResponse ~= obj.param('Target')
                % false
                Par.RespValid = false;
                Par.CurrResponse = Par.RESP_FALSE;
                if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
                    Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
                    Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
                end
                Par.FalseResponseGiven=true;
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
    end
end

