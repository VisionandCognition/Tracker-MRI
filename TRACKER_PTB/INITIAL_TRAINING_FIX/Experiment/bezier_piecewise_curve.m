function pts = bezier_piecewise_curve(pt1, pt2, angle1, angle2, d1, d2, n_ret_points)
% Piecewise bezier curves can be used to create composite curves. It is
% what is used in most vector-based graphics.
% The curve starts on pt1 and pt2. The off-curve points are calculated with
% the angles (angle1, angle2) and distances (d1, d2).

%global Par; % Temporary

tb = linspace(0, 1, n_ret_points);
pta = pt1 + d1 * [cos(angle1*pi/180), -sin(angle1*pi/180)];
ptb = pt2 + d2 * [cos(angle2*pi/180), -sin(angle2*pi/180)];
pts = kron((1-tb).^3,pt1') + kron(3*(1-tb).^2.*tb,pta') + kron(3*(1-tb).*tb.^2,ptb') + kron(tb.^3,pt2');
pts = pts';

r = 12;
spline_pts = [pt1; pta; ptb; pt2];
% for i = 1:size(spline_pts,1)
%     pt = spline_pts(i, :);
%     rect = [pt(1)-r, pt(2)-r, pt(1)+r, pt(2)+r]; %[left top right bottom];
%     Screen('FillOval', Par.window, [1, 0, 0].*Par.ScrWhite, ...
%             rect);
% end