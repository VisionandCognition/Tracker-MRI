function drawTarget(obj, color, offset, which_side, pawIndSizePix)
global Par

    %pawIndSizePix = obj.param('PawIndSizePix');
    pawIndCol = obj.param('PawIndCol');

    if length(color) == 1
        alpha = color;
        color = (...
            (1 - alpha)*obj.param('BGColor') + ...
            pawIndCol(which_side,:) * alpha) * Par.ScrWhite;
    end
    % Fixation position
    hfix = obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1);
    vfix = obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2);
    fix_pos = ...
        [hfix, vfix; ...
        hfix, vfix; ...
        hfix, vfix; ...
        hfix, vfix];
    for define_square=1 % left / square
        lmost=-pawIndSizePix/2;
        rmost= pawIndSizePix/2;
        tmost=-pawIndSizePix/2;
        bmost= pawIndSizePix/2;
        left_square = [lmost,tmost; ...
            rmost,tmost; ...
            rmost,bmost; ...
            lmost,bmost ...
            ];
    end
    for define_diamond=1 % right / diamond
        lmost=-sqrt(2)*pawIndSizePix/2;
        rmost= sqrt(2)*pawIndSizePix/2;
        tmost=-sqrt(2)*pawIndSizePix/2;
        bmost= sqrt(2)*pawIndSizePix/2;
        right_diamond = [lmost,0; ...
            0,tmost; ...
            rmost,0; ...
            0,bmost ...
            ];
    end
    if which_side == 1 % ---- Green Square
        Screen('FillPoly',Par.window,...
            color,...
            fix_pos + left_square + offset);
    elseif which_side == 2 % ---- Red Diamond
        Screen('FillPoly',Par.window,...
            color,...
            fix_pos + right_diamond + offset);
    elseif which_side == 3 % ---- Ambiguous Circle
        lmost=-sqrt(1/pi);
        rmost= sqrt(1/pi);
        tmost=-sqrt(1/pi);
        bmost= sqrt(1/pi);
        wait_circle = [lmost, tmost, rmost, bmost] .* pawIndSizePix;
        pos = repmat(fix_pos(1,:),[1,2]) + repmat(offset(1,:),[1,2]);
        Screen('FillOval', Par.window, color, ...
            pos + wait_circle);
    else
        assert(false);
    end
end