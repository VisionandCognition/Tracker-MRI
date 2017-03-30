function drawFix(obj)
% draw fixation point
    global Par

    fix_pos = obj.taskParams.FixPositionsPix(Par.PosNr,:)+Par.ScrCenter(:)';
    dot_radius = obj.param('FixDotSizePix')/2;
    rect=[...
        fix_pos - dot_radius, ...
        fix_pos + dot_radius];
    
    fixCol = obj.taskParams.FixDotCol(Par.FixIn+1,:).*Par.ScrWhite;
    Screen('FillOval',Par.window, fixCol, rect);
    
    if strcmp(obj.state, 'FIXATION_PERIOD') % black dot in center

        fix_pos = obj.taskParams.FixPositionsPix(Par.PosNr,:)+Par.ScrCenter(:)';
        dot_radius = obj.param('FixDotSizePix')/2/3;
        rect=[...
            fix_pos - dot_radius, ...
            fix_pos + dot_radius];
        Screen('FillOval',Par.window, [255 255 255].*Par.ScrWhite, rect);
    end
end