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
    obj.set_param('Connection1', ...
        [obj.param('GapL'), obj.param('GapL'), obj.param('GapR'), obj.param('GapR')]);
    obj.set_param('Connection2', ...
        [obj.param('GapUL'), obj.param('GapDL'), obj.param('GapUR'), obj.param('GapDR')]);
    obj.set_param('CurveSeg1', ...
        [obj.param('CurveSegL', 1), obj.param('CurveSegL', 1), obj.param('CurveSegR', 1), obj.param('CurveSegR', 1)]);
    obj.set_param('CurveSeg2', ...
        [obj.param('CurveSegUL', 1), obj.param('CurveSegDL', 1), obj.param('CurveSegUR', 1), obj.param('CurveSegDR', 1)]);
    
    obj.set_param('RandomGoSwitchDelay', ...
        rand(1)*obj.taskParams.EventPeriods(2)/1000);
end 