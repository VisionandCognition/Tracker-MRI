function lft = drawStimuli(obj, lft)
global Par;
global Log;

    if strcmp(obj.state, 'PREFIXATION')==1
        obj.drawBackgroundFixPoint();
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        Log.events.screen_flip(lft, obj.taskName);
        return;
    end
    
    obj.drawBackgroundFixPoint();
    
    %% change the checkerboard contrast if required
    if obj.TrackingCheckerContChange
        if lft-obj.tLastCheckerContChange >= ...
                1/obj.taskParams.RetMap.Checker.FlickFreq_Approx
            if obj.ChkNum==1
                obj.ChkNum=2;
            elseif obj.ChkNum==2
                obj.ChkNum=1;
            end
            obj.tLastCheckerContChange=lft;
        end
    else
        obj.tLastCheckerContChange=lft;
        obj.TrackingCheckerContChange=true;
    end

    Screen('DrawTexture',Par.window,obj.CheckTexture(obj.ChkNum),[],[],[],1);
    % lft = GetSecs; % ????
    % Draw on screen
    lft = Screen('Flip', Par.window, lft+.9*Par.fliptimeSec);
    Log.events.screen_flip(lft, obj.taskName);
end