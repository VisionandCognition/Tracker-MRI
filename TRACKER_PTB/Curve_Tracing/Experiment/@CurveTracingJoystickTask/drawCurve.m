function drawCurve(obj, indpos)
    global Par;
    
    [CurveAnglesAtFP, status] = obj.param('CurveAnglesAtFP');
    if ~status
        return
    end
    pos = obj.param('PawIndOffsetPix');
    pos = pos(indpos,:);  % Matlab doesn't allow indexing on returned values
    connection1 = obj.param('Connection1');
    connection1 = connection1(indpos);
    connection2 = obj.param('Connection2');
    connection2 = connection2(indpos);
    
    STR_IDENTICAL = 1; % Matlab's strcmp doesn't follow normal strcmp conventions
    if strcmp(obj.state, 'PRESWITCH') ~= STR_IDENTICAL
        connection1 = connection1 * obj.taskParams.PostSwitchJointAlpha;
        connection2 = connection2 * obj.taskParams.PostSwitchJointAlpha;
    end
    
    npoints = 500;
    fix = obj.taskParams.FixPositionsPix(Par.PosNr,:) + Par.ScrCenter;

    pt1 = [ cos(CurveAnglesAtFP(indpos)*pi/180), ...
           -sin(CurveAnglesAtFP(indpos)*pi/180)] * ...
           obj.param('BranchDistDeg') * Par.PixPerDeg;
    pt2 = [ cos(CurveAnglesAtFP(indpos)*pi/180), ...
           -sin(CurveAnglesAtFP(indpos)*pi/180)] * ...
           obj.param('CurveTargetDistDeg') * Par.PixPerDeg;
    spline_pts = [fix(1), fix(2); ...
                  fix(1)+pt1(1), fix(2)+pt1(2);
                  fix(1)+pos(1)-pt2(1), fix(2)+pos(2)-pt2(2);
                  fix(1)+pos(1), fix(2)+pos(2)];

    pts = bezier_curve_with_lines(spline_pts, round([npoints npoints npoints]/3));

    curveAlpha = obj.param('CurveAlpha');
    base_alpha = curveAlpha(~strcmp(obj.state, 'PRESWITCH')+1, ...
        indpos);
    if connection1 && connection2
        pts_alpha = repmat(base_alpha, [size(pts,1), 1]);
    else
        pts_alpha = repmat(base_alpha, [size(pts,1), 1]);

        ptD = [0; cumsum(sqrt(diff(pts(:,1)).^2 + diff(pts(:,2)).^2))];

        gap1_deg = obj.param('Gap1_deg');
        gap2_deg = obj.param('Gap2_deg');
        pts_alpha(~connection1 & ...
            ptD >= gap1_deg(1)*Par.PixPerDeg & ...
            ptD < gap1_deg(2)*Par.PixPerDeg) = nan;
        pts_alpha(~connection2 & ...
            ptD >= gap2_deg(1)*Par.PixPerDeg & ...
            ptD < gap2_deg(2)*Par.PixPerDeg) = nan;
    end
    linecol = [repmat(obj.param('TraceCurveCol'), [size(pts,1) 1]), pts_alpha] * Par.ScrWhite;
    draw_curve_along_pts(Par.window, ...
        pts(:,1), pts(:,2), obj.param('TraceCurveWidth'), linecol);
end