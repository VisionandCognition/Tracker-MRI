function drawFix(obj, Stm)
% draw fixation point
global Par

    fix_pos = Stm(1).Center(Par.PosNr,:)+Par.ScrCenter(:)';
    rect=[...
        Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)-Stm(1).FixDotSizePix/2, ...
        Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)-Stm(1).FixDotSizePix/2, ...
        Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1)+Stm(1).FixDotSizePix/2, ...
        Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2)+Stm(1).FixDotSizePix/2];
    if Par.RequireFixation
        % fixation area
        Screen('FillOval',Par.window, Par.CurrFixCol, rect);
    else
        Screen('FillOval',Par.window, Stm(1).FixDotCol(3,:).*Par.ScrWhite, rect);
    end
end