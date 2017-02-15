function drawFix(obj)
% draw fixation point
    global Par

    fix_pos = obj.taskParams.FixPositionsPix(Par.PosNr,:)+Par.ScrCenter(:)';
    dot_radius = obj.param('FixDotSizePix')/2;
    rect=[...
        fix_pos - dot_radius, ...
        fix_pos + dot_radius];
    if Par.RequireFixation
        % Par.CurrFixCol can vary 
        Screen('FillOval',Par.window, Par.CurrFixCol, rect);
    else
        Screen('FillOval',Par.window, ...
            obj.taskParams.FixDotCol(3,:).*Par.ScrWhite, rect);
    end
end