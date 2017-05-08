 function [lft] = drawStimuli(obj, lft)
 global Par;
 global Log;
 
    if strcmp(obj.state, 'PREFIXATION')==1
        obj.drawBackgroundFixPoint();
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        Log.events.screen_flip(lft, obj.taskName);
        return;
    end
 
    % Background
    Screen('FillRect', Par.window, obj.param('BGColor').*Par.ScrWhite);
    
    % Special cases with no fixation point
    if strcmp(obj.state, 'INIT_TRIAL')==1 ||  ...
            strcmp(obj.state, 'TRIAL_END')==1 || ...
            strcmp(obj.state, 'POSTSWITCH')==1 || ...
            strcmp(obj.state, 'END_TRIAL')==1
        
        lft = Screen('Flip', Par.window,lft+.9*Par.fliptimeSec); 
        Log.events.screen_flip(lft, obj.taskName);
        return;
    end

    obj.drawFix();  % -------------- Fixation point
    
    obj.update(); % Draws some of the stimuli (curves, targets)

    
    if strcmp(obj.state, 'POSTSWITCH') ~= 1
        % Target bar - "Go bar"
        if ~obj.taskParams.GoBarOrientation(obj.goBarOrient) %horizontal
            rect=[...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(1)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(2)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(1)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(2)/2];
        else
            rect=[...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(2)/2, ... left
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(1)/2, ... top
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(2)/2, ... right
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(1)/2];
        end

        Screen('FillRect', Par.window, obj.taskParams.GoBarColor .* Par.ScrWhite, rect);
    end
    
    % Draw on screen
    lft = Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    Log.events.screen_flip(lft, obj.taskName);
end
