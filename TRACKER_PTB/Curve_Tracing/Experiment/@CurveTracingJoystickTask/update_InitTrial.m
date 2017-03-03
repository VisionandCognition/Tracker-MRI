function update_InitTrial(obj)
% Setup the stimuli information that varies per trial
global Par;
global Log;

    obj.curr_response = 'none';
    obj.iTrialOfBlock = mod(obj.iTrialOfBlock, obj.param('BlockSize')) + 1;
    if obj.iTrialOfBlock == 1
        obj.blockNum = obj.blockNum + 1;
    end
    
    obj.curr_stim_index = obj.selectTrialStimulus(); %randi(size(obj.stimuli_params, 1), 1);
    curr_stim = table2cell(obj.stimuli_params(obj.curr_stim_index, :));
    obj.curr_stim = containers.Map(...
        obj.stimuli_params.Properties.VariableNames, curr_stim);
    
    Log.events.add_entry(nan, obj.taskName, 'NewStimulus', obj.curr_stim_index);
    Log.events.add_entry(nan, obj.taskName, 'TargetLoc', obj.param('TargetLoc'));
    
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
    obj.set_param('TargetShape', targetShape);
    
    STR_IDENTICAL = 1; % Matlab's strcmp doesn't follow standard
    if strcmp(targetShape, 'Square')==STR_IDENTICAL
        obj.set_param('iTargetShape', 1);
    else
        assert(strcmp(targetShape, 'Diamond')==STR_IDENTICAL)
        obj.set_param('iTargetShape', 2);
    end
    
    obj.set_param('RandomGoSwitchDelay', ...
        rand(1)*obj.taskParams.EventPeriods(2)/1000);
    
    
    obj.trial_log.recordTrialStimulus(obj.curr_stim);
end 