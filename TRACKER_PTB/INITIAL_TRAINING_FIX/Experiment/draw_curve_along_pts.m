function draw_curve_along_pts(windowPtr, pts_x, pts_y, linethick, linecol)

% xnan = any(isnan(pts_x),1);
% xd = abs(diff(xnan));
% if isnan(pts_x(1))
%     xd = [0 xd];
% else
%     xd = [1 xd];
% end
% segments = cumsum(xd);

x1 = pts_x(1:end-2); % start of lines (make lines overlap)
x2 = pts_x(3:end); % end of lines
x_lines = [x1(:)'; x2(:)'];

y1 = pts_y(1:end-2);
y2 = pts_y(3:end);
y_lines = [y1(:)'; y2(:)'];
xy = [x_lines(:)'; y_lines(:)'];

if length(linecol) == 1
    linecols = linecol;
else
    c1 = linecol(1:end-2,:);
    c2 = linecol(3:end,:);
    linecols = column_interleave(c1, c2);
end

smo = 2;
lenient = 0;
Screen('DrawLines', windowPtr, xy, linethick, linecols, ...
    [0, 0], smo, lenient);
end