function pts = cubic_spline_curve(spline_pts, npoints)
global Par;

% d0 = d0 / 10;
% d1 = d1 / 10;
% d4 = d4 / 10;
% 
% t_total = linspace(0,1,npoints);
% npoints_0 = round(npoints * 0.2); % straight segment
% npoints_b = npoints - npoints_0;  % bezier curve
% 
% pt1 = pt0 + d0 * [cos(angle1*pi/180); -sin(angle1*pi/180)];
% 
% line_pts = [...
%     linspace(pt0(1), pt1(1), npoints_0); ...
%     linspace(pt0(2), pt1(2), npoints_0)];
% 
% pt2 = pt1 + d1 * [cos(angle1*pi/180); -sin(angle1*pi/180)];
% pt3 = pt4 + d4 * [cos(angle4*pi/180); -sin(angle4*pi/180)];
% 
% tb = linspace(0,1,npoints_b);
% pts_bezier = kron((1-tb).^3,pt1) + kron(3*(1-tb).^2.*tb,pt2) + kron(3*(1-tb).*tb.^2,pt3) + kron(tb.^3,pt4);
% 
pts_spline_x = linspace(spline_pts(1,1), spline_pts(end,1), npoints);
pts_spline_y = spline(spline_pts(:,1),...
                      spline_pts(:,2),...
                      pts_spline_x);

pts = [pts_spline_x; pts_spline_y];

r = 12;
%dots = [pt0 pt1 pt2 pt3 pt4];
for i = 1:size(spline_pts,1)
    pt = spline_pts(i, :);
    rect = [pt(1)-r, pt(2)-r, pt(1)+r, pt(2)+r]; %[left top right bottom];
    Screen('FillOval', Par.window, [1, 0, 0].*Par.ScrWhite, ...
            rect);
end

return