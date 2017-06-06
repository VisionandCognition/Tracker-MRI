function readStimulusParamsForTrial(obj, stim_index)
% Setup the stimuli information that varies per trial. Called each trial.
global Par;
% This function should not log anything, update_InitTrial should.
    
    curr_stim = table2cell(obj.stimuli_params(stim_index, :));
    obj.curr_stim = containers.Map(...
        obj.stimuli_params.Properties.VariableNames, curr_stim);    
    
    Par.TaskSwitched = false;

    obj.set_param('PawIndOffsetPix', ...
        obj.param('PawIndPositions') * Par.PixPerDeg);
    
    % Set information of the paws
    obj.set_param('PawIndSizePix', ...
        round(obj.param('PawIndSizeDeg') .* Par.PixPerDeg));
    obj.set_param('PawIndOffsetPix', ...
        obj.param('PawIndPositions') .* Par.PixPerDeg);
    
    % make variables accessible by indexing
    obj.set_param('Connection1', ...
        [obj.param('GapL'), obj.param('GapL'), obj.param('GapR'), obj.param('GapR')]);
    obj.set_param('Connection2', ...
        [obj.param('GapUL'), obj.param('GapDL'), obj.param('GapUR'), obj.param('GapDR')]);
    obj.set_param('CurveSeg1', ...
        [obj.param('CurveSegL', 1), obj.param('CurveSegL', 1), obj.param('CurveSegR', 1), obj.param('CurveSegR', 1)]);
    obj.set_param('CurveSeg2', ...
        [obj.param('CurveSegUL', 1), obj.param('CurveSegDL', 1), obj.param('CurveSegUR', 1), obj.param('CurveSegDR', 1)]);
    
    if obj.param('NumOfPawIndicators')==4
        targetIndicators = ...
            { obj.param('IndicatorUL'), obj.param('IndicatorDL'), ...
              obj.param('IndicatorUR'), obj.param('IndicatorDR')};
    else
        assert(obj.param('NumOfPawIndicators')==5)
        targetIndicators = ...
            { obj.param('IndicatorUL'), obj.param('IndicatorDL'), ...
              obj.param('IndicatorUR'), obj.param('IndicatorDR'), ...
              obj.param('IndicatorCenter')};
    end
    sideIndicators = zeros(length(targetIndicators),1);
    for i = 1:length(targetIndicators)
        switch(targetIndicators{i})
            case 'Square' % left response
                sideIndicators(i) = 1;
            case 'Diamond' % right response
                sideIndicators(i) = 2;
            otherwise
                sideIndicators(i) = nan; % don't show
        end
    end
    obj.set_param('SideIndicators', sideIndicators);
    
    switch obj.param('TargetLoc')
        case 'UL'
            obj.set_param('iTargetLoc', 1);
        case 'DL'
            obj.set_param('iTargetLoc', 2);
        case 'UR'
            obj.set_param('iTargetLoc', 3);
        case 'DR'
            obj.set_param('iTargetLoc', 4);
        case 'Center'
            obj.set_param('iTargetLoc', 5);
        otherwise
            assert(false, sprintf('Unknown TargetLoc %s', ...
                obj.param('TargetLoc')));
    end
    
    % Process the target/correct response
    targetShapeVar = sprintf('Indicator%s', obj.param('TargetLoc'));
    targetShape = obj.param(targetShapeVar);
    assert(strcmp(obj.curr_stim('TargetShape'), targetShape), ...
        ['Inconsistent TargetShape parameter in row ' stim_index ...
        ' of ' obj.stimuliParamsPath]);
    obj.set_param('TargetShape', targetShape);
    
    STR_IDENTICAL = 1; % Matlab's strcmp doesn't follow standard
    if strcmp(targetShape, 'Square')==STR_IDENTICAL
        assert(obj.curr_stim('iTargetShape') == 1, ...
            ['Inconsistent iTargetShape parameter in row ' stim_index ...
            ' of ' obj.stimuliParamsPath]);
        obj.set_param('iTargetShape', 1);
    else
        assert(strcmp(targetShape, 'Diamond')==STR_IDENTICAL)
        assert(obj.curr_stim('iTargetShape') == 2, ...
            ['Inconsistent iTargetShape parameter in row ' stim_index ...
            ' of ' obj.stimuliParamsPath]);
        obj.set_param('iTargetShape', 2);
    end
    
    obj.set_param('RandomGoSwitchDelay', ...
        rand(1)*obj.taskParams.EventPeriods(2)/1000);
end 