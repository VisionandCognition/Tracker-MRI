function move_dots()

% Oval / Rectangle / N / U
mask.type = 'Rectangle';

switch mask.type
    case 'Oval'
        % Oval
        mask.vert=[.25 .75];
        mask.hor=[.2 .8];
        mask.center = [mean(mask.hor) mean(mask.vert)];
        mask.r = [ diff(mask.hor)/2 diff(mask.vert)/2 ];
        % checking if a pointis inside ellipse:
        % ((x-mask.center(1)).^2)/(mask.r(1).^2) + ((y-mask.center(2)).^2)/(mask.r(2).^2)
        % <1    inside ellipse
        % ==1   on the circumference
        % >1    outside
    case 'Rectangle'
        mask.vert=[.25 .75];
        mask.hor=[.2 .8];
    case 'N'
        % N/U shape
        legwidth = .2; bridgewidth=.1;
        mask.vert=[.25 .75];
        mask.hor=[.2 .8];
        mask.lx=[mask.hor(1) mask.hor(1)+legwidth];
        mask.rx=[mask.hor(2)-legwidth mask.hor(2)];
        mask.bridge=[mask.vert(2)-bridgewidth mask.vert(2)];
    case 'U'
        % N/U shape
        legwidth = .2; bridgewidth=.1;
        mask.vert=[.25 .75];
        mask.hor=[.2 .8];
        mask.lx=[mask.hor(1) mask.hor(1)+legwidth];
        mask.rx=[mask.hor(2)-legwidth mask.hor(2)];
        mask.bridge=[mask.vert(1) mask.vert(1)+bridgewidth];
end       
        
ndots=5000;
for i=1:2; dots(i).pos = rand(ndots,2); end


% f1=figure;
% subplot(1,2,1); hold on
% scatter(dots(1).pos(:,1),dots(1).pos(:,2))
% scatter(dots(2).pos(:,1),dots(2).pos(:,2))
% set(gca, 'xlim',[0 1],'ylim',[0 1]);
% 
% subplot(1,2,2); hold on
% %scatter(dots(1).pos(:,1),dots(1).pos(:,2),'x')
% mbool = getmbool(dots(1).pos,mask);
% scatter(dots(1).pos(~mbool,1),dots(1).pos(~mbool,2))
% 
% %scatter(dots(2).pos(:,1),dots(2).pos(:,2),'x')
% mbool = getmbool(dots(2).pos,mask);
% scatter(dots(2).pos(mbool,1),dots(2).pos(mbool,2))
% set(gca, 'xlim',[0 1],'ylim',[0 1]);

f2=figure;
pause(1);
step=0.002;
for i=1:100
    dots(1).pos=dots(1).pos+step;
    if any(dots(1).pos>1)
        dots(1).pos(dots(1).pos>1) = dots(1).pos(dots(1).pos>1)-1;
    end
    if any(dots(1).pos<0)
        dots(1).pos(dots(1).pos<0) = dots(1).pos(dots(1).pos<1)+1;
    end
    
    dots(2).pos=dots(2).pos-step;
    if any(dots(2).pos>1)
        dots(2).pos(dots(2).pos>1) = dots(2).pos(dots(2).pos>1)-1;
    end
    if any(dots(2).pos<0)
        dots(2).pos(dots(2).pos<0) = dots(2).pos(dots(2).pos<0)+1;
    end
    
    hold on
    cla;
    mbool = getmbool(dots(1).pos,mask);
    scatter(dots(1).pos(~mbool,1),dots(1).pos(~mbool,2),'k.')
    
    mbool = getmbool(dots(2).pos,mask);
    scatter(dots(2).pos(mbool,1),dots(2).pos(mbool,2),'k.')
    set(gca, 'xlim',[0 1],'ylim',[0 1]);
    hold off
    pause(0.01);
end

    function mbool = getmbool(pos,mask)
        switch mask.type
            case 'N'
                mbool = ...
                    (pos(:,1) > mask.lx(1) & pos(:,1) < mask.lx(2) & ...
                    pos(:,2) > mask.vert(1) & pos(:,2) < mask.vert(2)) | ...
                    (pos(:,1) > mask.rx(1) & pos(:,1) < mask.rx(2) & ...
                    pos(:,2) > mask.vert(1) & pos(:,2) < mask.vert(2)) | ...
                    (pos(:,1) > mask.hor(1) & pos(:,1) < mask.hor(2) & ...
                    pos(:,2) > mask.bridge(1) & pos(:,2) < mask.bridge(2));
            case 'U'
                mbool = ...
                    (pos(:,1) > mask.lx(1) & pos(:,1) < mask.lx(2) & ...
                    pos(:,2) > mask.vert(1) & pos(:,2) < mask.vert(2)) | ...
                    (pos(:,1) > mask.rx(1) & pos(:,1) < mask.rx(2) & ...
                    pos(:,2) > mask.vert(1) & pos(:,2) < mask.vert(2)) | ...
                    (pos(:,1) > mask.hor(1) & pos(:,1) < mask.hor(2) & ...
                    pos(:,2) > mask.bridge(1) & pos(:,2) < mask.bridge(2));
            case 'Oval'
                mbool = ...
                    ((pos(:,1)-mask.center(1)).^2)/(mask.r(1).^2) + ...
                    ((pos(:,2)-mask.center(2)).^2)/(mask.r(2).^2) < 1;
            case 'Rectangle'
                mbool = ...
                    (pos(:,1) > mask.hor(1) & pos(:,1) < mask.hor(2) & ...
                    pos(:,2) > mask.vert(1) & pos(:,2) < mask.vert(2));
        end
    end
end