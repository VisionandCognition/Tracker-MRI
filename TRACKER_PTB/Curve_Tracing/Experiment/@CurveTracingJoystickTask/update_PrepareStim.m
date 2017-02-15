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
    for i=1:size(obj.taskParams.FixPositionsDeg,2);
        obj.taskParams.FixPositionsPix(i,:) = round(...
            obj.taskParams.FixPositionsDeg{i}.*Par.PixPerDeg);
    end
    Par.CurrOrient=1; % 1=default, 2=switched

    Par.Paused = false;
end