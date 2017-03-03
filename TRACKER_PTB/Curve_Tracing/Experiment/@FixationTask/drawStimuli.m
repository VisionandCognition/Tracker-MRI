 function [lft] = drawStimuli(obj, lft) % For fixation task
 global Par;
 global Log;
 
    % Background
    Screen('FillRect', Par.window, obj.param('BGColor').*Par.ScrWhite);
    
    switch(obj.state)
        case 'INIT_TRIAL'
        case 'PREFIXATION'
            obj.drawFix();
        case 'FIXATION_PERIOD'
            obj.drawFix();
        case 'POSTFIXATION'
        case 'END_TRIAL'
        otherwise
            assert(false); % there are no other states
    end
    
    % Draw on screen
    lft = Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    Log.events.screen_flip(lft, obj.taskName);
end
