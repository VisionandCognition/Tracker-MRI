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