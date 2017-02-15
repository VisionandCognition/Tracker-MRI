function drawBackgroundFixPoint(obj)
% Draw background and possibly fixation point
global Par

    % Background
    Screen('FillRect',Par.window, obj.param('BGColor').*Par.ScrWhite);
    if Par.Paused
        % Dark background
        Screen('FillRect',Par.window, 0.0 * obj.param('BGColor').*Par.ScrWhite);
    elseif ~Par.GoNewTrial
        if strcmp(obj.state,'INIT_TRIAL')
            %                 if Stm(1).NumBeams == 2 && Par.BeamLIsBlocked
            %                     Screen('DrawLine', Par.window, ...
            %                         Stm(1).PawIndCol(1,:), ...
            %                         0, 0, ...
            %                         0, Par.ScreenHeightD2);
            %                 end
            %                 if Stm(1).NumBeams == 2 && Par.BeamRIsBlocked
            %                     Screen('DrawLine', Par.window, ...
            %                         Stm(1).PawIndCol(2,:), ...
            %                         Par.ScreenWidthD2, 0, ...
            %                         Par.ScreenWidthD2, Par.ScreenHeightD2);
            %                 end

            % Semi-dark / brown background
            Screen('FillRect',Par.window, [.5 .25 0].*Par.ScrWhite);
        else
            % Dark background
            Screen('FillRect',Par.window, 0.0 * obj.param('BGColor').*Par.ScrWhite);
        end
    end
    if ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked && ~Par.Paused
        % Draw fixation dot
        obj.drawFix();
    end
end
