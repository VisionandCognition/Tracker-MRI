function drawCurve(obj, pos, connection1, connection2, indpos, Par, Stm)
    if ~isfield(Par, 'CurveAngles')
        return
    end
    npoints = 500;
    distractor = ~(connection1 && connection2);
    hfix = Stm(1).Center(Par.PosNr,1)+Par.ScrCenter(1);
    vfix = Stm(1).Center(Par.PosNr,2)+Par.ScrCenter(2);
    d1 = sqrt(pos(1)^2 + pos(2)^2);

%         pts = bezier_curve_angle3([hfix; vfix], ...
%             [hfix+pos(1); vfix+pos(2)], Par.CurveAngles(indpos), d1, ...
%                 npoints);
    if mod(Par.CurveAngles(indpos)+90, 360) < 180
        target_angle = 180;
    else
        target_angle = 0;
    end
    pts = bezier_curve_angle([hfix; vfix], ...
        [hfix+pos(1); vfix+pos(2)], ...
        Par.CurveAngles(indpos), target_angle, ...
        d1, d1/4, ...
            npoints);

    alpha = Stm(1).CurveAlpha(~strcmp(Par.State, 'PRESWITCH')+1, ...
        indpos);
    if connection1 && connection2
        base_alpha = alpha;
    else
        if connection2 % Small gap to fixation point
            Gap = Stm(1).GapFraction1;
        else % larger gap
            Gap = Stm(1).GapFraction2;
        end

        base_alpha = Par.unattended_alpha * alpha;
        % calculate total distance (to edge of target)
        TD = sum(sqrt(diff(pts(1,:)).^2 + diff(pts(2,:)).^2)) - ...
            Stm(1).PawIndSize / 2 * Par.PixPerDeg;
        % calculate distance of gap
        GD = TD * Gap;
        % distance from each point to fixation point
        ptD = [0 cumsum(sqrt(diff(pts(1,:)).^2 + diff(pts(2,:)).^2))];
        % pts outside of gap
        pts = pts(:, ptD >= GD);
    end
    linecol = [Stm(1).TraceCurveCol base_alpha] * Par.ScrWhite;
    draw_curve_along_pts(Par.window, ...
        pts(1,:), pts(2,:), Stm(1).TraceCurveWidth, linecol);
end