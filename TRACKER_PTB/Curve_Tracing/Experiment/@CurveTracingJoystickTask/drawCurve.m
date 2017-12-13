function drawCurve(obj, indpos)
% Draw a single curve from fixation to index position indpos
    global Par;
    
    fix_offset = obj.taskParams.FixPositionsPix(Par.PosNr,:);
    
    pts = obj.curves{obj.curr_stim_index, indpos, 1};
    if any(isnan(pts))
        % curve target is the fixation point - ie. don't need curve
        return;
    end
    pts = pts + repmat(fix_offset, size(pts,1),1);
    pts_col = obj.curves{obj.curr_stim_index, indpos, 2};
            
    draw_curve_along_pts(Par.window, ...
        pts(:,1), pts(:,2), obj.param('TraceCurveWidth'), pts_col);
end