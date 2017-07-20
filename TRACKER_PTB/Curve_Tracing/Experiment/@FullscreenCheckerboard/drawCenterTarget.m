function drawCenterTarget(obj, lft)
% This function is used when there is just one true target, the center
% target.
global Par;

    centerPawIndOffsetPix = obj.param('CenterPawIndOffsetPix');
    
    pawIndCol = obj.param('PawIndCol');
    centerPawIndAlpha = obj.param('PawIndAlpha');
    centerPawIndAlpha = centerPawIndAlpha(:,5);
 
    %% change the checkerboard contrast if required
    if obj.TrackingCheckerContChange
        if lft-obj.tLastCheckerContChange >= ...
                1/obj.taskParams.RetMap.Checker.FlickFreq_Approx
            if obj.ChkNum==1
                obj.ChkNum=2;
            elseif obj.ChkNum==2
                obj.ChkNum=1;
            end
            obj.tLastCheckerContChange=lft;
        end
    else
        obj.tLastCheckerContChange=lft;
        obj.TrackingCheckerContChange=true;
    end

    if strcmp(obj.state, 'PRESWITCH')
        % ------------------------------- PRESWITCH
        %hfix = obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1); %Stm(1).Center
        %vfix = obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2); 
        fix = obj.taskParams.FixPositionsPix(Par.PosNr,:) + Par.ScrCenter;
        fix_pos = [fix; fix; fix; fix];
        
        preSwitchCenterShapeIndex = obj.param('PreSwitchCenterShapeIndex');

        offset = repmat( ...
            centerPawIndOffsetPix, [4,1]);

        if ~isnan(preSwitchCenterShapeIndex)
            Color_obj = pawIndCol(preSwitchCenterShapeIndex,:) * ...
                centerPawIndAlpha(2);
            color = Color_obj * Par.ScrWhite;

            centerPawIndSizePix = obj.param('CenterPawIndSizePix');
            drawTarget(obj, color, offset, preSwitchCenterShapeIndex, centerPawIndSizePix);
        end
        
    elseif strcmp(obj.state, 'SWITCHED')
        % ------------------------------- SWITCHED

        centerShapeIndex = obj.param('CenterShapeIndex');
        offset = repmat( ...
            centerPawIndOffsetPix, [4,1]);

        if ~isnan(centerShapeIndex)
            Color_obj = pawIndCol(centerShapeIndex,:) * ...
                centerPawIndAlpha(2);
            Unattd_color = Color_obj * Par.ScrWhite;

            centerPawIndSizePix = obj.param('CenterPawIndSizePix');
            obj.drawTarget(Unattd_color, offset, centerShapeIndex, centerPawIndSizePix)
        end

    end
    if strcmp(obj.state, 'PRESWITCH') || strcmp(obj.state, 'SWITCHED')
    %if strcmp(obj.state, 'POSTSWITCH') ~= 1
        % Target bar - "Go bar"
        if ~obj.taskParams.GoBarOrientation(obj.goBarOrient) %horizontal
            rect=[...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(1)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(2)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(1)/2, ...
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(2)/2];
        else
            rect=[...
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(2)/2, ... left
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(1)/2, ... top
                obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(2)/2, ... right
                obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(1)/2];
        end

        Screen('FillRect', Par.window, obj.taskParams.GoBarColor .* Par.ScrWhite, rect);
    end
end