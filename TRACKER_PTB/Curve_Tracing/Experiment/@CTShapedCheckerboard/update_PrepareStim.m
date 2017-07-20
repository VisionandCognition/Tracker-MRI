function update_PrepareStim(obj)
global Par;

    update_PrepareStim@FullscreenCheckerboard(obj)

    num_stim = size(obj.curve_stimuli_params, 1);
    obj.curves = cell( ...
        num_stim, ... number of curve stimuli (does not control center target)
        obj.param('NumOfPawIndicators'), ... targets
        2); % pts or pts_col
    
    sz = size(obj.CB1);
    
    [X, Y] = meshgrid([-sz(1)/2:-1, 1:sz(1)/2], [-sz(2)/2:-1, 1:sz(2)/2]);
    
    %curve_width_px = obj.param('TraceCurveWidth');
    curve_width_px = obj.param('TraceCurveWidthDeg') * Par.PixPerDeg;
    
    CB1 = obj.CB1;
    CB2 = obj.CB2;
    
    obj.taskParams.PawIndOffsetPix = ...
        obj.taskParams.PawIndPositions * Par.PixPerDeg;
    
    for stim_index=1:num_stim
        % should read parameters for the curve_stimuli, not the center
        % target
        %obj.readStimulusParamsForTrial(stim_index, obj.curve_stimuli_params);
        
        obj.curr_curve_stim = containers.Map(...
            obj.curve_stimuli_params.Properties.VariableNames, ...
            table2cell(obj.curve_stimuli_params(stim_index, :)));
        
        targetIndicators = ...
            { obj.param('IndicatorUL'), obj.param('IndicatorDL'), ...
              obj.param('IndicatorUR'), obj.param('IndicatorDR')};
        
        % Perform some of the functions for readStimulusForTrial
        % make variables accessible by indexing
        obj.set_param('Connection1', ...
            [obj.param('GapL'), obj.param('GapL'), obj.param('GapR'), obj.param('GapR')]);
        obj.set_param('Connection2', ...
            [obj.param('GapUL'), obj.param('GapDL'), obj.param('GapUR'), obj.param('GapDR')]);
        obj.set_param('CurveSeg1', ...
            [obj.param('CurveSegL', 1), obj.param('CurveSegL', 1), obj.param('CurveSegR', 1), obj.param('CurveSegR', 1)]);
        obj.set_param('CurveSeg2', ...
            [obj.param('CurveSegUL', 1), obj.param('CurveSegDL', 1), obj.param('CurveSegUR', 1), obj.param('CurveSegDR', 1)]);
        
        % Set information of the paws
        pawIndSizePix = obj.param('PawIndSizeDeg') .* Par.PixPerDeg;
        obj.set_param('PawIndSizePix', ...
            pawIndSizePix);
        pawIndOffsetPix = obj.param('PawIndPositions') .* Par.PixPerDeg;
        obj.set_param('PawIndOffsetPix', ...
            pawIndOffsetPix);
        
        curr_mask = zeros(sz(1:2));
        for indpos = 1:obj.param('NumOfPawIndicators')
            % Curve points are in pixels and calculated from
            % the upper left of Screen
            [pts, pts_col] = obj.calcCurve(indpos);
             % adjust points to be relative to center
            pts = pts - repmat(Par.ScrCenter, [size(pts,1), 1]);
            for i=1:size(pts,1)
                if isnan(pts_col(i,4))
                    continue
                end
                curr_mask( ...
                    ((X - pts(i,1)).^2 + (Y - pts(i,2)).^2) < ...
                    (curve_width_px./2).^2) = 255;
            end
            if ~isempty(targetIndicators{indpos})
                pt = pawIndOffsetPix(indpos,:);
                % ignore the actual shape
                curr_mask( ...
                    ((X - pt(:,1)).^2 + (Y - pt(:,2)).^2) < ...
                    (pawIndSizePix(indpos)./2).^2) = 255;
            end
        end
        CB1(:,:,4) = curr_mask;
        CB2(:,:,4) = curr_mask;
        obj.maskedCBTexture(1, stim_index)=Screen('MakeTexture', Par.window, CB1);
        obj.maskedCBTexture(2, stim_index)=Screen('MakeTexture', Par.window, CB2);
    end
    
end