function drawCurvesAndTargets(obj)
% Draws all curves
global Par;

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
        
        preSwitchShapeIndices = obj.param('PreSwitchShapeIndices');
        for indpos = 1:obj.param('NumOfPawIndicators')
            offset = repmat( ...
                PawIndOffsetPix(indpos,:), [4,1]);

            shapeIndex = preSwitchShapeIndices(indpos);
            if isnan(shapeIndex)
                continue
            end
            Color_obj = pawIndCol(shapeIndex,:) * ...
                pawIndAlpha(2, indpos);
            color = Color_obj * Par.ScrWhite;

            pawIndSizePix = obj.param('PawIndSizePix');
            pawIndSizePix = pawIndSizePix(indpos);
            drawTarget(obj, color, offset, shapeIndex, pawIndSizePix);
        end
    elseif strcmp(obj.state, 'SWITCHED')
        % ------------------------------- SWITCHED

        shapeIndices = obj.param('ShapeIndices');
        for indpos = 1:obj.param('NumOfPawIndicators')
            offset = repmat( ...
                PawIndOffsetPix(indpos,:), [4,1]);

            shapeIndex = shapeIndices(indpos);
            if isnan(shapeIndex)
                continue
            end

            Color_obj = pawIndCol(shapeIndex,:) * ...
                pawIndAlpha(2, indpos);
            Unattd_color = Color_obj * Par.ScrWhite;

            pawIndSizePix = obj.param('PawIndSizePix');
            pawIndSizePix = pawIndSizePix(indpos);
            obj.drawTarget(Unattd_color, offset, shapeIndex, pawIndSizePix)
        end
    end
end