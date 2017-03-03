function update_PreOrPostSwitch(obj)
global Par;

    PawIndSizePix = obj.param('PawIndSizePix');
    PawIndOffsetPix = obj.param('PawIndOffsetPix');
    
    pawIndCol = obj.param('PawIndCol');
    pawIndAlpha = obj.param('PawIndAlpha');

    for indpos = 1:obj.param('NumOfPawIndicators')
        obj.drawCurve(indpos);
    end
    
    if strcmp(obj.state, 'PRESWITCH')
        % ------------------------------- PRESWITCH
        %hfix = obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1); %Stm(1).Center
        %vfix = obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2); 
        fix = obj.taskParams.FixPositionsPix(Par.PosNr,:) + Par.ScrCenter;
        fix_pos = [fix; fix; fix; fix];
        
        pawIndAlpha = obj.param('PawIndAlpha');
        for indpos = 1:obj.param('NumOfPawIndicators')
            offset = repmat( ...
                PawIndOffsetPix(indpos,:), [4,1]);

            obj.drawPreSwitchFigure(Par, ...
                fix_pos(1,:)+offset(1,:), ...
                PawIndSizePix(indpos),  ...
                pawIndAlpha(1, indpos));
        end
    else
        % ------------------------------- POSTSWITCH

        sideIndicators = obj.param('SideIndicators');
        for indpos = 1:obj.param('NumOfPawIndicators')
            offset = repmat( ...
                PawIndOffsetPix(indpos,:), [4,1]);

            side = sideIndicators(indpos);
            if isnan(side)
                continue
            end

            Color_obj = pawIndCol(side,:) * ...
                pawIndAlpha(2, indpos);
            Unattd_color = Color_obj * Par.ScrWhite;

            pawIndSizePix = obj.param('PawIndSizePix');
            pawIndSizePix = pawIndSizePix(indpos);
            obj.drawTarget(Unattd_color, offset, side, pawIndSizePix)
        end
    end
end