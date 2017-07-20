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
    
    obj.drawCenterTarget(lft);

    Screen('DrawTexture',Par.window,obj.CheckTexture(obj.ChkNum),[],[],[],1);
    lft = GetSecs; % ????
    % Draw on screen
    lft = Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    Log.events.screen_flip(lft, obj.taskName);
end