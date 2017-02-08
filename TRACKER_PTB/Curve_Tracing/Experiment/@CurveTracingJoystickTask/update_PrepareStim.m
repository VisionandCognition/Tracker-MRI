function [Par, Stm] = update_PrepareStim(obj, Par, Stm)

    obj.curr_stim_index = randi(size(obj.stimuli_params, 1), 1);
    obj.curr_stim = obj.stimuli_params(obj.curr_stim_index, :);
    
    % Fixation
    Stm(1).FixWinSizePix = round(Stm(1).FixWinSize*Par.PixPerDeg);
    Stm(1).FixDotSizePix = round(Stm(1).FixDotSize*Par.PixPerDeg);

    % Bar
    Stm(1).SizePix = round(Stm(1).Size.*Par.PixPerDeg);
    Stm(1).Center =[];
    for i=1:size(Stm(1).Position,2);
        Stm(1).Center =[Stm(1).Center; ...
            round(Stm(1).Position{i}.*Par.PixPerDeg)];
    end
    Par.CurrOrient=1; % 1=default, 2=switched

    % Paw indicator
    Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
    Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);

    %Par.PawSide=randi([1,2]);
    % PawSides indicate the side (1 or 2) for each paw indicator
    % Side 1 is left (green square)
    % Side 2 is right (red diamond)
    % The first PawSides is the indicator that should be attended
    if Stm(1).NumOfPawIndicators > 1
        Par.PawSides(:) = 0;
        for i = 1:Stm(1).NumOfPawIndicators/2
            Par.PawSides(2*i-1:2*i) = randperm(2);
        end
    else
        Par.PawSides = randi([1,2]);
    end
    [Par, Stm] = obj.RandomizePawIndOffset(Par, Stm);

    if ~isfield(Par, 'AutoCycleTasks')
        Par.AutoCycleTasks = 0; % do not cycle tasks automatically
    end

    Par.Paused = false;
    Par.unattended_alpha = max(Stm(1).UnattdAlpha); % redefined later, randomly
    Par.trial_preswitch_alpha = max(Stm(1).AlphaPreSwitch);

    % Noise patch
    Stm(1).NoiseSizePix = round(Stm(1).NoiseSize.*Par.PixPerDeg);
    % Square noise patch of window-height
    NoiPatch = (.5-Stm(1).NoiseContrast/2) + ...
        (Stm(1).NoiseContrast.*rand(Par.HH*2));
    NoiPatch_RGB = ones(Par.HH*2,Par.HH*2,4);
    NoiPatch_RGB(:,:,1)=NoiPatch;
    NoiPatch_RGB(:,:,2)=NoiPatch;
    NoiPatch_RGB(:,:,3)=NoiPatch;
    % alpha mask circular
    c=Par.HH;
    s=Par.HH*2;
    r=Stm(1).NoiseSizePix/2;
    [x,y]=meshgrid(-(c-1):(s-c),-(c-1):(s-c));
    alphamask=((x.^2+y.^2)<=r^2);
    NoiPatch_RGB(:,:,4)=alphamask;
    % Make a texture of the noise patch
    NoiTex=Screen('MakeTexture',Par.window,NoiPatch_RGB.*Par.ScrWhite);

    if size(Stm(1).PawIndAlpha,1)==1
        Stm(1).PawIndAlpha = [ ...
            Stm(1).PawIndAlpha; ... PreSwitch Alpha
            Stm(1).PawIndAlpha ... PostSwitchAlpha
            ];
    end
end