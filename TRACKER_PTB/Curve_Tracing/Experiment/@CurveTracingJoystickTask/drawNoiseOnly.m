% draw stimuli
function drawNoiseOnly(obj, Stm)
global Par

    % Background
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);
    if Par.Paused
        % Dark background
        Screen('FillRect',Par.window, 0.0 * Par.BG.*Par.ScrWhite);
    elseif ~Par.GoNewTrial
        if strcmp(Par.State,'INIT')
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
            Screen('FillRect',Par.window, 0.0 * Par.BG.*Par.ScrWhite);
        end
    end
    if ~Par.BeamLIsBlocked && ~Par.BeamRIsBlocked && ~Par.Paused
        % Noise patch
        if Par.DrawNoise
            srcRect = [Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5 ...
                Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
            destRect = [Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-(Stm(1).NoiseSizePix/2)-5 ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-(Stm(1).NoiseSizePix/2)-5 ...
                Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+(Stm(1).NoiseSizePix/2)+5 ...
                Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+(Stm(1).NoiseSizePix/2)+5];
            Screen('DrawTexture',Par.window,NoiTex,srcRect,destRect);
        end
        % Draw fixation dot
        obj.drawFix(Stm);
    end
end
