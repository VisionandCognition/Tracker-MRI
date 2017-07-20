function readStimulusParamsForTrial(obj, stim_index)
% Setup the stimuli information that varies per trial. Called each trial.
global Par;
% This function should not log anything, update_InitTrial should.
    
    curr_stim = table2cell(obj.stimuli_params(stim_index, :));
    obj.curr_stim = containers.Map(...
        obj.stimuli_params.Properties.VariableNames, curr_stim);    
    
    Par.TaskSwitched = false;
    
    % Set information of the center paw indicator
    centerPawIndSizeDeg = obj.param('PawIndSizeDeg');
    centerPawIndSizeDeg = centerPawIndSizeDeg(5);
    obj.set_param('CenterPawIndSizePix', ...
        centerPawIndSizeDeg .* Par.PixPerDeg);
    
    centerPawIndPos = obj.param('PawIndPositions');
    centerPawIndPos = centerPawIndPos(5,:);
    obj.set_param('CenterPawIndOffsetPix', ...
        centerPawIndPos .* Par.PixPerDeg);
    
    % make variables accessible by indexing
%     obj.set_param('Connection1', ...
%         [obj.param('GapL'), obj.param('GapL'), obj.param('GapR'), obj.param('GapR')]);
%     obj.set_param('Connection2', ...
%         [obj.param('GapUL'), obj.param('GapDL'), obj.param('GapUR'), obj.param('GapDR')]);
%     obj.set_param('CurveSeg1', ...
%         [obj.param('CurveSegL', 1), obj.param('CurveSegL', 1), obj.param('CurveSegR', 1), obj.param('CurveSegR', 1)]);
%     obj.set_param('CurveSeg2', ...
%         [obj.param('CurveSegUL', 1), obj.param('CurveSegDL', 1), obj.param('CurveSegUR', 1), obj.param('CurveSegDR', 1)]);

    centerTargetIndicator = obj.param('IndicatorCenter');
          
    preSwitchCenterTargetIndicator = obj.param('PreSwitchCenter', 'Circle');

    switch(centerTargetIndicator)
        case 'Square' % left response
            centerShapeIndex = 1;
        case 'Diamond' % right response
            centerShapeIndex = 2;
        case 'Circle' % wait / ambiguous - used in PreSwitch
            centerShapeIndex = 3;
        otherwise
            centerShapeIndex = nan; % don't show
    end
    obj.set_param('CenterShapeIndex', centerShapeIndex);
    
    switch(preSwitchCenterTargetIndicator)
        case 'Square' % left response
            preSwitchCenterShapeIndex = 1;
        case 'Diamond' % right response
            preSwitchCenterShapeIndex = 2;
        case 'Circle' % wait / ambiguous - used in PreSwitch
            preSwitchCenterShapeIndex = 3;
        otherwise
            preSwitchCenterShapeIndex = nan; % don't show
    end
    obj.set_param('PreSwitchCenterShapeIndex', preSwitchCenterShapeIndex);
    
%     switch obj.param('TargetLoc')
%         case 'UL'
%             obj.set_param('iTargetLoc', 1);
%         case 'DL'
%             obj.set_param('iTargetLoc', 2);
%         case 'UR'
%             obj.set_param('iTargetLoc', 3);
%         case 'DR'
%             obj.set_param('iTargetLoc', 4);
%         case 'Center'
%             obj.set_param('iTargetLoc', 5);
%         otherwise
%             assert(false, sprintf('Unknown TargetLoc %s', ...
%                 obj.param('TargetLoc')));
%     end

    % For FullscreenCheckerboard, target is always center (5)
    obj.set_param('iTargetLoc', 5);
    
    % Process the target/correct response
    targetShapeVar = 'IndicatorCenter';
    targetShape = obj.param(targetShapeVar);
    assert(strcmp(obj.curr_stim('TargetShape'), targetShape), ...
        ['Inconsistent TargetShape parameter in row ' stim_index ...
        ' of ' obj.stimuliParamsPath]);
    obj.set_param('TargetShape', targetShape);
    
    if strcmp(targetShape, 'Square')
        assert(obj.curr_stim('iTargetShape') == 1, ...
            ['Inconsistent iTargetShape parameter in row ' stim_index ...
            ' of ' obj.stimuliParamsPath]);
        obj.set_param('iTargetShape', 1);
    else
        assert(strcmp(targetShape, 'Diamond'))
        assert(obj.curr_stim('iTargetShape') == 2, ...
            ['Inconsistent iTargetShape parameter in row ' stim_index ...
            ' of ' obj.stimuliParamsPath]);
        obj.set_param('iTargetShape', 2);
    end
    
    obj.set_param('RandomGoSwitchDelay', ...
        rand(1)*obj.taskParams.EventPeriods(2)/1000);
end 