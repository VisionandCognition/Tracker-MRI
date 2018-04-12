function drawPreSwitchFigure(obj, Par, offset, pawIndSizePix, alpha)
%     lmost=-sqrt(1/pi);
%     rmost= sqrt(1/pi);
%     tmost=-sqrt(1/pi);
%     bmost= sqrt(1/pi);
%     wait_circle = [lmost, tmost, rmost, bmost];

    pawIndCol = obj.param('PawIndCol');
    color = (1 - alpha)*obj.param('BGColor') + ...
        pawIndCol(3,:) .* alpha;
     
%     Screen('FillOval', Par.window, color .*Par.ScrWhite, ...
%         repmat(pos(1,:),[1,2]) + wait_circle*SizePix);
    
    drawTarget(obj, color, offset, which_side, pawIndSizePix);
end