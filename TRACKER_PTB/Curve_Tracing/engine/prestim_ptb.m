%Prestim
%Updated 19_10_2011 Chris van der Togt
%Updated to take PTB3 commands instead of cogent: Sept 2013 Chris Klink

global Par;

for InitializeDasAndPTB=1 %allows code folding
    %% Das card
    BtOn = 0;  %if using button presses set to 1
    Par.Board = int32(22);  %mcc board = 22; Demo-board = 0
    Par.nChannels = 8;
    if ~isfield(Par, 'DasOn')
        Par.DasOn = 0; %persistent value
    end
    
    if Par.DasOn ~= 1
        %LPStat = dasinit( Par.Board, Par.nChannels);  %mexfunction acces!!
        dasinit( Par.Board, Par.nChannels);  %mexfunction acces!!
        Par.DasOn = 1;
    end
    
    %% PTB
    warning('off','MATLAB:dispatcher:InexactMatch')
        
    if ~isfield(Par,'window') % assume that is a window has een opened, it's still there
        ptbInit % initialize PTB
        Par.scr=Screen('screens');
        Par.ScrNr=max(Par.scr); % use the screen with the highest #
        PsychImaging('PrepareConfiguration');
        % Check which screen and flip if 3T BOLD
        if strcmp(Par.ScreenChoice,'3T'); % 3T
            % flip horizontal
            PsychImaging('AddTask','AllViews','FlipHorizontal');
            fprintf([Par.ScreenChoice ' BOLD display: Flipping the screen\n']);
        elseif strcmp(Par.ScreenChoice,'Mock')% mock
            % specific mock stuff?
        else
        end
        %[Par.window, Par.wrect] = Screen('OpenWindow',Par.ScrNr,0,[],[],2,[],[],1);
        [Par.window, Par.wrect] = PsychImaging('OpenWindow',Par.ScrNr,0,[],[],2,[],[],1);
    end
    
    %Set-up blend function
    [sourceFactorOld,destinationFactorOld,colorMaskOld] = ...
        Screen('BlendFunction',Par.window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    
    %% set eyerec trigger to 'off'
    dasbit(0,1);
end

%////////////////////global variable Par settings//////////////////////////
% default file assignment
% make sure they exist and have all necessary parameters
Par.RUNFUNC = 'runstim';
Par.STIMSETFILE = 'StimSettings';
Par.PARSETFILE = 'ParSettings';
Par.MONKEY = 'DefMonkey';

eval(Par.PARSETFILE); %loads parameter settings from separate m-file
