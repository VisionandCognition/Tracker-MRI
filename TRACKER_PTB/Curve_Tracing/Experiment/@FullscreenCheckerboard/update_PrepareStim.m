function update_PrepareStim(obj)
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

    %% fullscreen checkerboard
    %Stm(STIMNR).Descript = 'FullChecker';
    %DispChecker=true;
    fn = obj.taskParams.RetMap.Checker.FileName;
    fn = strrep(fn,'[MRI_SETUP]',Par.SetUp);
    path = ['Stimuli', filesep, 'fullchecker', filesep, fn];
            
    if obj.taskParams.RetMap.Checker.LoadFromFile && exist(path, 'file') == 2
        fprintf(['\nLoading checkerboard ' ...
            obj.taskParams.RetMap.Checker.FileName '...\n']);

        load(path);
    else
        fprintf('\nCreating checkerboard...\n');
        % create the checkerboard
        chksize = ceil(obj.taskParams.RetMap.Checker.Size*Par.PixPerDeg);
        chkimg = double(RadialCheckerBoard(...
            [chksize ...
            ceil(obj.taskParams.RetMap.Checker.centerradius*Par.PixPerDeg)], ...
            obj.taskParams.RetMap.Checker.Sector, ...
            obj.taskParams.RetMap.Checker.chsz));
        
        if obj.taskParams.RetMap.Checker.SaveToFile
            fprintf('\nSaving checkerboard...\n');
            
            if ~exist(fileparts(path), 'dir') == 7
                mkdir(fileparts(path));
            end
            save(path,'chkimg');
        end
    end
    % create texture
    CB1R = chkimg(:,:,1)./Par.ScrWhite;
    CB1R(chkimg(:,:,1)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,1);
    CB1R(chkimg(:,:,1)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,1);
    CB1G=chkimg(:,:,1)./Par.ScrWhite;
    CB1G(chkimg(:,:,1)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,2);
    CB1G(chkimg(:,:,1)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,2);
    CB1B=chkimg(:,:,1)./Par.ScrWhite;
    CB1B(chkimg(:,:,1)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,3);
    CB1B(chkimg(:,:,1)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,3);
    CB1A = chkimg(:,:,3);
    CB1 = CB1R.*Par.ScrWhite;
    CB1(:,:,2)=CB1G.*Par.ScrWhite;
    CB1(:,:,3)=CB1B.*Par.ScrWhite;
    %CB1(:,:,4)=CB1A;
    CB1(:,:,4)=CB1A *1; % Make more transparent

    CB2R = chkimg(:,:,2)./Par.ScrWhite;
    CB2R(chkimg(:,:,2)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,1);
    CB2R(chkimg(:,:,2)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,1);
    CB2G=chkimg(:,:,2)./Par.ScrWhite;
    CB2G(chkimg(:,:,2)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,2);
    CB2G(chkimg(:,:,2)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,2);
    CB2B=chkimg(:,:,2)./Par.ScrWhite;
    CB2B(chkimg(:,:,2)==Par.ScrWhite) = ...
        obj.taskParams.RetMap.Checker.Colors(1,3);
    CB2B(chkimg(:,:,2)==0) = ...
        obj.taskParams.RetMap.Checker.Colors(2,3);
    CB2A = chkimg(:,:,3);
    CB2 = CB2R.*Par.ScrWhite;
    CB2(:,:,2)=CB2G.*Par.ScrWhite;
    CB2(:,:,3)=CB2B.*Par.ScrWhite;
    %CB2(:,:,4)=CB2A;
    CB2(:,:,4)=CB2A *1; % Make more transparent

    obj.CheckTexture(1)=Screen('MakeTexture', Par.window, CB1);
    obj.CheckTexture(2)=Screen('MakeTexture', Par.window, CB2);
    obj.TrackingCheckerContChange = false;
end

% create radial checkerboard
function chkimg = RadialCheckerBoard(radius, sector, chsz)
global Par;
    %img = RadialCheckerBoard(radius, sector, chsz, propel)
    % Returns a bitmap image of a radial checkerboard pattern.
    % The image is a square of 2*OuterRadius pixels.
    %
    % Parameters of wedge:
    %   radius :    eccentricity of radii in pixels = [outer, inner]
    %   sector :    polar angles in degrees = [start, end] from -180 to 180
    %   chsz :      size of checks in log factors & degrees respectively = [eccentricity, angle]
    %   propel :    Optional, if defined there are two wedges, one in each hemifield
    %
    checkerboard = [0 Par.ScrWhite; Par.ScrWhite 0];
    img = ones(2*radius(1), 2*radius(1)) * ceil(Par.ScrWhite/2);

    for x = -radius : radius
        for y = -radius : radius
            [th, r] = cart2pol(x,y);
            th = th * 180/pi;
            if th >= sector(1) && th < sector(2) && r < radius(1) && r > radius(2)
                img(y+radius(1)+1,x+radius(1)+1) = checkerboard(mod(floor(log(r)*chsz(1)),2) + 1, mod(floor((th + sector(1))/chsz(2)),2) + 1);
            end
        end
    end
    img = flipud(img);

    if nargin > 3
        rotimg = rot90(img,2);
        non_grey_pixels = find(rotimg ~= ceil(Par.ScrWhite/2));
        img(non_grey_pixels) = rotimg(non_grey_pixels);
    end
    img = uint8(img);

    width = radius(1)*2;
    [X, Y] = meshgrid([-width/2:-1 1:width/2], [-width/2:-1 1:width/2]);
    [T, R] = cart2pol(X,Y);
    circap = ones(width, width);
    circap(R > width/2) = 1;
    alphas = linspace(1, 0, 0);
    circap(R > width/2) = 0;
    circap(R < radius(2)) = 0;
    chkimg = img;
    chkimg(:,:,2) = uint8(abs(double(img)-Par.ScrWhite));
    chkimg(:,:,3)=circap.*Par.ScrWhite;
end