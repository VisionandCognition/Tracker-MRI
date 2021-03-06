function [pts, pts_col] = calcCurve(obj, indpos)
% CALCCURVE Calculates the points on a curve, with the points defined in
% visual degrees.

    global Par;
    
    CurveAnglesAtFP = obj.param('CurveAnglesAtFP');

    pos = obj.param('PawIndOffsetPix');
    pos = pos(indpos,:);  % Matlab doesn't allow indexing on returned values
    if all(pos==0) % if target is at fixation point, don't draw curve!
        pts = NaN;
        pts_col = NaN;
        return;
    end
    % (FP) [Conn1] ---CurveSeg1--- [Conn2] ---CurveSeg2---[Target]
    connection1 = obj.param('Connection1'); % "gap" between FP and Seg1
    connection1 = connection1(indpos);
    
    nongap_seg1 = obj.param('CurveSeg1');
    nongap_seg1 = nongap_seg1(indpos);
    
    connection2 = obj.param('Connection2');
    connection2 = connection2(indpos);
    
    nongap_seg2 = obj.param('CurveSeg2');
    nongap_seg2 = nongap_seg2(indpos);
    
    STR_IDENTICAL = 1; % Matlab's strcmp doesn't follow normal strcmp conventions
    if strcmp(obj.state, 'PRESWITCH') ~= STR_IDENTICAL
        connection1 = connection1 * obj.taskParams.PostSwitchJointAlpha;
        connection2 = connection2 * obj.taskParams.PostSwitchJointAlpha;
    end
    
    npoints = 500;
    fix = Par.ScrCenter; % obj.taskParams.FixPositionsPix(Par.PosNr,:) + 

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
    
    if connection1 && connection2 && nongap_seg1 && nongap_seg2
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
        
        % segments between the gaps
        pts_alpha(~nongap_seg1 & ...
            ptD >= gap1_deg(2)*Par.PixPerDeg & ...
            ptD < gap2_deg(1)*Par.PixPerDeg) = nan;
        
        pts_alpha(~nongap_seg2 & ...
            ptD >= gap2_deg(2)*Par.PixPerDeg) = nan;
        
        % don't draw to the center of the target
        
        pawIndSizePix = obj.param('PawIndSizePix');
        pawIndSizePix = pawIndSizePix(indpos);
        pts_mask = (ptD(end) - ptD) >= pawIndSizePix/2;
        pts_alpha(~pts_mask) = nan;
    end
    pts_col = [repmat(obj.param('TraceCurveCol'), [size(pts,1) 1]), pts_alpha] * Par.ScrWhite;
end