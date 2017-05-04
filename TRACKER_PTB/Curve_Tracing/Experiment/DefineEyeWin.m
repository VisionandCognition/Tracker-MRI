function DefineEyeWin
% create fixation window around target

global Par;
global StimObj;

Stm = StimObj.Stm;

    FIX = 0;  %this is the fixation window
    TALT = 1; %this is an alternative/erroneous target window --> not used
    TARG = 2; %this is the correct target window --> not used
    FixWinSizePix = Stm(1).task.param('FixWinSizePix');
    Par.WIN = [...
        Stm(1).task.taskParams.FixPositionsPix(Par.PosNr,:), ...
        FixWinSizePix, ...
        FixWinSizePix, FIX]';
    refreshtracker( 1) %clear tracker screen and set fixation and target windows
    SetWindowDas; %set das control thresholds using global parameters : Par
end