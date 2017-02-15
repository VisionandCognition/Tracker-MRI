function drawPreSwitchFigure(obj, Par, pos, SizePix, alpha)
    lmost=-sqrt(1/pi);
    rmost= sqrt(1/pi);
    tmost=-sqrt(1/pi);
    bmost= sqrt(1/pi);
    wait_circle = [lmost, tmost, rmost, bmost];
    color = (1 - alpha)*obj.param('BGColor') + ...
        [0.6, 0.6, 0.6].* alpha;
    Screen('FillOval', Par.window, color .*Par.ScrWhite, ...
        repmat(pos(1,:),[1,2]) + wait_circle*SizePix);
end