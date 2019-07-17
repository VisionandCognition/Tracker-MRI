%StimSettings
global StimObj

%% Refreshrate ------------------------------------------------------------
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

%% Background -------------------------------------------------------------
Stm.BackColor =  [.667 .667 .667]; % [R G B] 0-1

%% Timing -----------------------------------------------------------------
% pre-defined in ParSettings at init: will be overwritten with these values
Stm.PreFixT = 5000; % time to enter fixation window
Stm.FixT = 300; % time to fix before stim onset
Stm.KeepFixT = [1000 100]; % [mean sd] of NORM % time to fix before target onset. not <|> m+/-sd
Stm.PreTargFlashDur = 1000;%500;
Stm.ReacT = 2000; % max allowed reaction time (leave fixwin after target onset)
Stm.StimT = Stm.KeepFixT(1) + Stm.ReacT; % stimulus display duration
Stm.SaccT = 500; % max allowed saccade time (from leave fixwin to enter target win)
Stm.ErrT = 500; % punishment extra ISI after error trial (there are no error trials here)
Stm.ErrT_onEarly = true; % consider early saccades to be errors
Stm.ISI = 500; % base inter-stimulus interval
Stm.ISI_RAND = 100; % maximum extra (random) ISI to break any possible rythm

%% Fixation ---------------------------------------------------------------
%NB! may be overruled in the parsettings file
%Stm.FixWinSize = [10 10]; % [W H] in deg 
%NB! may be overruled in the parsettings file

Stm.FixDotSize = 0.15;
Stm.FixDotCol = [.3 .3 .3 ; .1 .1 .1]; %[Hold ; Respond]
Stm.FixRemoveOnGo = true;
Stm.FixWinSize = [2 2];

% Fixation position can be toggled with 1-5 keys --------------------------
Stm.Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm.Position{2} = [-4 -4]; % deg from center (-=left/down)
Stm.Position{3} = [+4 -4]; % deg from center (-=left/down)
Stm.Position{4} = [-4 +4]; % deg from center (-=left/down)
Stm.Position{5} = [+4 +4]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm.CyclePosition = 0; % set zero for manual cycling
% Stm.Color = [0 1 0]; % [R G B] 0-1

%% Choice target stimuli ==================================================
TarCreateAlgorithm = 2;
% 1=manual / 2=algorithm single stim / 3=algorithm two stim

if TarCreateAlgorithm == 1
    % Manual target settings //////////////////////////////////////////
    Stm.RandomizeCond=true;
    Stm.nRepeatsStimSet=5;
    
    % shapes: 'circle','square','diamond'
    % maximum of 2 targets per stimulus
    %--- Condition 1 -----
    c=1;
    Stm.Cond(c).Targ(1).Shape = 'circle';
    Stm.Cond(c).Targ(1).Size = 2; % diameter in deg
    Stm.Cond(c).Targ(1).WinSize = 2.5; % deg
    Stm.Cond(c).Targ(1).Position = [-6 0]; % deg
    Stm.Cond(c).Targ(1).Color = [1 0 0]; % RGB 0-1
    Stm.Cond(c).Targ(1).PreTargCol = [0.2 0.2 0.2];
    Stm.Cond(c).Targ(1).Reward = 0.04;
    
    % Stm.Cond(c).Targ(2).Shape = 'circle';
    % Stm.Cond(c).Targ(2).Size = 3; % diameter in deg
    % Stm.Cond(c).Targ(2).WinSize = 4; % deg
    % Stm.Cond(c).Targ(2).Position = [+5 0]; % deg
    % Stm.Cond(c).Targ(2).Color = [1 0 0]; % RGB 0-1
    % Stm.Cond(c).Targ(2).PreTargCol = [0.2 0.2 0.2];
    % Stm.Cond(c).Targ(2).Reward = 0.1;
    
    %--- Condition 2 -----
    % c=2;
    % Stm.Cond(c).Targ(1).Shape = 'diamond';
    % Stm.Cond(c).Targ(1).Size = 3; % diameter in deg
    % Stm.Cond(c).Targ(1).WinSize = 4; % deg
    % Stm.Cond(c).Targ(1).Position = [-3 -3]; % deg
    % Stm.Cond(c).Targ(1).Color = [1 1 0]; % RGB 0-1
    % Stm.Cond(c).Targ(1).PreTargCol = [0.2 0.2 0.2];
    % Stm.Cond(c).Targ(1).PreTargFlashDur = 0.050;
    % Stm.Cond(c).Targ(1).Reward = 0.04;
    %
    % Stm.Cond(c).Targ(2).Shape = 'square';
    % Stm.Cond(c).Targ(2).Size = 2; % diameter in deg
    % Stm.Cond(c).Targ(2).WinSize = 4; % deg
    % Stm.Cond(c).Targ(2).Position = [3 -3]; % deg
    % Stm.Cond(c).Targ(2).Color = [0 1 1]; % RGB 0-1
    % Stm.Cond(c).Targ(2).PreTargCol = [0.2 0.2 0.2];
    % Stm.Cond(c).Targ(2).Reward = 0.1;
elseif TarCreateAlgorithm == 2
    % Algorithm to create many conditions (single stim) ///////////////
    Stm.RandomizeCond=true;
    Stm.nRepeatsStimSet=10;
    
    % place stimuli on an imaginary circle around screen center
    Stm.PolarAngles = 0:10:359 ; % deg
    %Stm.PolarAngles = [210*ones(1,1000) -30*ones(1,1000)]; % deg
    Stm.Eccentricity = 5.0; % deg
    
    x=Stm.Eccentricity.*cosd(Stm.PolarAngles);
    y=Stm.Eccentricity.*sind(Stm.PolarAngles);
    Stm.TarPos = [x' y'];
    
    for c=1:length(Stm.PolarAngles)
        Stm.Cond(c).Targ(1).Shape = 'circle';
        Stm.Cond(c).Targ(1).Size = 1.5; % diameter in deg
        Stm.Cond(c).Targ(1).WinSize = 2; % deg
        Stm.Cond(c).Targ(1).Position = Stm.TarPos(c,:); % deg
        Stm.Cond(c).Targ(1).Color = [.1 .1 .1]; % RGB 0-1
        %Stm.Cond(c).Targ(1).PreTargCol = 3*Stm.Cond(c).Targ(1).Color;
        Stm.Cond(c).Targ(1).PreTargCol = [0.65 0.65 0.65];
        Stm.Cond(c).Targ(1).Reward = 0.120;
    end
end

% Logfolder
Stm.LogFolder = 'C:\Users\NINuser\Documents\Log_CK\ChoiceSaccade';

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;