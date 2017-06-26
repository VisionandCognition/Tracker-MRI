function lft = drawStimuli(obj, lft)
global Par;
global Log;

    if strcmp(obj.state, 'PREFIXATION')==1
        obj.drawBackgroundFixPoint();
        % Draw on screen
        lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
        Log.events.screen_flip(lft, obj.taskName);
        return;
    end
    
    PawIndOffsetPix = obj.param('PawIndOffsetPix');
    
    pawIndCol = obj.param('PawIndCol');
    pawIndAlpha = obj.param('PawIndAlpha');
 
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

    Screen('DrawTexture',Par.window,obj.CheckTexture(obj.ChkNum),[],[],[],1);
    lft = GetSecs; % ????
    % Draw on screen
    lft = Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
    Log.events.screen_flip(lft, obj.taskName);
end