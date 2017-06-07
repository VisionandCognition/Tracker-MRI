function drawBackgroundFixPoint(obj)
% Draw background and possibly fixation point
global Par

    % Background
    Screen('FillRect',Par.window, obj.param('BGColor').*Par.ScrWhite);
    if Par.Paused
        % Dark background
        Screen('FillRect',Par.window, 0.5 .* Par.ScrWhite);
    elseif ~Par.GoNewTrial
        if strcmp(obj.state,'INIT_TRIAL')
            % Semi-dark / brown background
            Screen('FillRect',Par.window, [.5 .25 0].*Par.ScrWhite);
        else
            % Dark background
            Screen('FillRect',Par.window, 0.5 .* Par.ScrWhite);
        end
    end
    if ~Par.Paused % ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked && 
        % Draw fixation dot
        obj.drawFix();
    end
end
