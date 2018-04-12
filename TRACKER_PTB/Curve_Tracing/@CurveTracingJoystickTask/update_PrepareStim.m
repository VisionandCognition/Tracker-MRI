function update_PrepareStim(obj)
% Prepare common stimulus settings.
% Any parameters could vary per trial should be set during INIT_TRIAL.
% Use taskParams, instead of param(),
% set_param() interface, which allows reading specific trial stimulus
% information.

global Par;

    % Fixation
    obj.taskParams.FixWinSizePix = ...
        round(obj.taskParams.FixWinSizeDeg*Par.PixPerDeg);
    obj.taskParams.FixDotSizePix = ...
        round(obj.taskParams.FixDotSizeDeg*Par.PixPerDeg);
    
    % Bar
    obj.taskParams.GoBarSizePix = round(obj.taskParams.GoBarSizeDeg.*Par.PixPerDeg);
    
    obj.taskParams.FixPositionsPix = zeros(...
        size(obj.taskParams.FixPositionsDeg,2), 2);
    for stim_index=1:size(obj.taskParams.FixPositionsDeg,2)
        obj.taskParams.FixPositionsPix(stim_index,:) = round(...
            obj.taskParams.FixPositionsDeg{stim_index}.*Par.PixPerDeg);
    end

    Par.Paused = false;
    
    obj.curves = cell( ...
        size(obj.stimuli_params, 1), ... number of stimuli
        obj.param('NumOfPawIndicators'), ... targets
        2); % pts or pts_col
    for stim_index=1:size(obj.stimuli_params, 1)
        obj.readStimulusParamsForTrial(stim_index);
        for indpos = 1:obj.param('NumOfPawIndicators')
            [pts, pts_col] = obj.calcCurve(indpos);
            obj.curves{stim_index, indpos, 1} = pts;
            obj.curves{stim_index, indpos, 2} = pts_col;
        end
    end
end