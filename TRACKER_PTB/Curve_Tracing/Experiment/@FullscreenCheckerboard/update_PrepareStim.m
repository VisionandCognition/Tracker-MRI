function update_PrepareStim(obj)
    %% fullscreen checkerboard
    fn_lead='fullchecker_';
    Stm(STIMNR).Descript = 'FullChecker';
    RetMapStimuli=false;
    DispChecker=true;
    if Stm(STIMNR).RetMap.Checker.LoadFromFile;
        fprintf(['\nLoading checkerboard ' ...
            Stm(STIMNR).RetMap.Checker.FileName '...\n']);
        cd Stimuli
        cd fullchecker
        load(Stm(STIMNR).RetMap.Checker.FileName);
        cd ..
        cd ..
    else
        fprintf('\nCreating checkerboard...\n');
        % create the checkerboard
        chksize = ceil(Stm(STIMNR).RetMap.Checker.Size*Par.PixPerDeg);
        chkimg = double(RadialCheckerBoard(...
            [chksize ...
            ceil(Stm(STIMNR).RetMap.Checker.centerradius*Par.PixPerDeg)], ...
            Stm(STIMNR).RetMap.Checker.Sector, ...
            Stm(STIMNR).RetMap.Checker.chsz));
        if Stm(STIMNR).RetMap.Checker.SaveToFile
            fprintf('\nSaving checkerboard...\n');
            cd Stimuli
            cd fullchecker
            save(Stm(STIMNR).RetMap.Checker.FileName,'chkimg');
            cd ..
            cd ..
        end
    end
    % create texture
    CB1R = chkimg(:,:,1)./Par.ScrWhite;
    CB1R(chkimg(:,:,1)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,1);
    CB1R(chkimg(:,:,1)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,1);
    CB1G=chkimg(:,:,1)./Par.ScrWhite;
    CB1G(chkimg(:,:,1)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,2);
    CB1G(chkimg(:,:,1)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,2);
    CB1B=chkimg(:,:,1)./Par.ScrWhite;
    CB1B(chkimg(:,:,1)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,3);
    CB1B(chkimg(:,:,1)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,3);
    CB1A = chkimg(:,:,3);
    CB1 = CB1R.*Par.ScrWhite;
    CB1(:,:,2)=CB1G.*Par.ScrWhite;
    CB1(:,:,3)=CB1B.*Par.ScrWhite;
    %CB1(:,:,4)=CB1A;
    CB1(:,:,4)=CB1A *1; % Make more transparent

    CB2R = chkimg(:,:,2)./Par.ScrWhite;
    CB2R(chkimg(:,:,2)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,1);
    CB2R(chkimg(:,:,2)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,1);
    CB2G=chkimg(:,:,2)./Par.ScrWhite;
    CB2G(chkimg(:,:,2)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,2);
    CB2G(chkimg(:,:,2)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,2);
    CB2B=chkimg(:,:,2)./Par.ScrWhite;
    CB2B(chkimg(:,:,2)==Par.ScrWhite) = ...
        Stm(STIMNR).RetMap.Checker.Colors(1,3);
    CB2B(chkimg(:,:,2)==0) = ...
        Stm(STIMNR).RetMap.Checker.Colors(2,3);
    CB2A = chkimg(:,:,3);
    CB2 = CB2R.*Par.ScrWhite;
    CB2(:,:,2)=CB2G.*Par.ScrWhite;
    CB2(:,:,3)=CB2B.*Par.ScrWhite;
    %CB2(:,:,4)=CB2A;
    CB2(:,:,4)=CB2A *1; % Make more transparent

    CheckTexture(1)=Screen('MakeTexture', Par.window, CB1);
    CheckTexture(2)=Screen('MakeTexture', Par.window, CB2);
    TrackingCheckerContChange = false;
end