function curve_pts = bezier_curve_with_lines(pts, npoints)
% Draw curves connecting pts, where the first two points and last two
% points are straight lines and the curve connecting the remaining middle
% section is a bezier curve.

% First section
x1 = linspace(pts(1,1), pts(2,1), npoints(1));
y1 = linspace(pts(1,2), pts(2,2), npoints(1));
seg1 = [x1', y1'];

% Middle section
d1 = (abs(pts(1,1) - pts(1, end))) * 0.33;
d2 = d1;
dx12 = pts(2,1) - pts(1,1);
dy12 = pts(2,2) - pts(1,2);
angle12_deg = atan2(-dy12, dx12)*180/pi;
dx34 = pts(3,1) - pts(4,1);
dy34 = pts(3,2) - pts(4,2);
angle34_deg = atan2(-dy34, dx34)*180/pi;
seg2 = bezier_piecewise_curve(pts(2,:), pts(3,:), ...
    angle12_deg, angle34_deg, d1, d2, npoints(2));

% Last section
x3 = linspace(pts(3,1), pts(4,1), npoints(3));
y3 = linspace(pts(3,2), pts(4,2), npoints(3));
seg3 = [x3', y3'];

curve_pts = [seg1; seg2; seg3];