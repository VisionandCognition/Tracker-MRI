 function DrawStimuli
    % Background
    Screen('FillRect',Par.window,Par.BG.*Par.ScrWhite);

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

    [Par, Stm] = Stm(1).Task.updateAndDraw(Par.State, Par, Stm);

    DrawFix;

    % Target bar - "Go bar"
    if ~Stm(1).Orientation(Par.CurrOrient) %horizontal
        rect=[...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(1)/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(2)/2, ...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(1)/2, ...
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).SizePix(2)/2];
    else
        rect=[...
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).SizePix(2)/2, ... left
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).SizePix(1)/2, ... top
            Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).SizePix(2)/2, ... right
            Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).SizePix(1)/2];
    end
    if ~Stm(1).Orientation(Par.CurrOrient) || Stm(1).ShowDistractBar
        Screen('FillRect',Par.window,Stm(1).Color.*Par.ScrWhite,rect);
    end
    % Draw on screen
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
end
