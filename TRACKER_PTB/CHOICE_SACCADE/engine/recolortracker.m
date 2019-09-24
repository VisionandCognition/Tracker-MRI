function recolortracker
persistent HArray
global Par

cla
WIN = Par.WIN;
nmW = size(WIN,2);
HArray = zeros(nmW+3,1);
ZM = Par.ZOOM;

fix.x = cos((1:61)/30*pi);
fix.y = sin((1:61)/30*pi);

if Par.Bsqr
    dot.x = [-1 1 1 -1 -1];
    dot.y = [-1 -1 1 1 -1];
else
    dot.x = cos((1:61)/30*pi);
    dot.y = sin((1:61)/30*pi);
end

% Screen rectangle
HArray(1) = line('XData', [-Par.HW Par.HW Par.HW -Par.HW -Par.HW]*ZM, ...
    'YData', [-Par.HH -Par.HH Par.HH Par.HH -Par.HH]*ZM);
if strcmp(Par.tracker_version, 'tracker_dark')
    set(HArray(1), 'Color','w'); % make screen border lines white
end

% Fix dot
HArray(2) = line('XData', WIN(1,1)*ZM, 'YData', WIN(2,1)*ZM);
set(HArray(2), 'Marker', 'o', 'MarkerSize', 10*ZM, 'MarkerFaceColor', 'r')

for i = 1:nmW
    if (WIN(5,i) == 0) %fix window
        HArray(4+i) = line('XData', (fix.x*WIN(3,i)*0.5+WIN(1,i))*ZM,...
            'YData', (fix.y*WIN(4,i)*0.5+WIN(2,i))*ZM);
        if strcmp(Par.tracker_version, 'tracker_dark')
            set(HArray(4+i), 'Color', 'w');
        end
        HArray(3) = line('XData', (fix.x*WIN(3,i)*0.5*sqrt(0.5)+WIN(1,i))*ZM,...
            'YData', (fix.y*WIN(4,i)*0.5*sqrt(0.5)+WIN(2,i))*ZM);
        set(HArray(3), 'Color', [0.7 0.7 0.7])
        if strcmp(Par.tracker_version, 'tracker_dark')
            set(HArray(3), 'Color', [0.5 0.5 0.5])
        end
    elseif(WIN(5,i) == 2) %2 == correct target window
        HArray(4) = line('XData', (dot.x*WIN(3,i)*0.5+WIN(1,i))*ZM, 'YData', (dot.y*WIN(4,i)*0.5+WIN(2,i))*ZM);
        set(HArray(4), 'Color', 'm')
    else
        HArray(4+i) = line('XData', (dot.x*WIN(3,i)*0.5+WIN(1,i))*ZM, 'YData', (dot.y*WIN(4,i)*0.5+WIN(2,i))*ZM);
        if strcmp(Par.tracker_version, 'tracker_dark')
            set(HArray(4+i), 'Color', 'w');
        end
    end
end