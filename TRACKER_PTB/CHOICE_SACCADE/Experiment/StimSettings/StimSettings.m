%StimSettings
global StimObj

%% Refreshrate ============================================================
Stm(1).UsePreDefFlipTime=false; %else as fast as possible
Stm(1).FlipTimePredef = 1/75;

%% Background =============================================================
Stm.BackColor = [.5 .5 .5]; % [R G B] 0-1

%% Timing =================================================================
% pre-defined in ParSettings at init: will be overwritten with these values
Stm.PreFixT = 5000; % time to enter fixation window
Stm.FixT = 500; % time to fix before stim onset
Stm.KeepFixT = 200; % time to fix before target onset. before 26-9-2014 this was 150
Stm.ReacT = 2000; % max allowed reaction time (leave fixwin after target onset)
Stm.StimT = Stm.KeepFixT + Stm.ReacT; % stimulus display duration
Stm.SaccT = 500; % max allowed saccade time (from leave fixwin to enter target win)
Stm.ErrT = 500; % punishment extra ISI after error trial (there are no error trials here)
Stm.ISI = 500; % base inter-stimulus interval
Stm.ISI_RAND = 200; % maximum extra (random) ISI to break any possible rythm

%% Fixation ===============================================================
%NB! may be overruled in the parsettings file
%Stm.FixWinSize = [10 10]; % [W H] in deg
%NB! may be overruled in the parsettings file

Stm.FixDotSize = 0.3;
Stm.FixDotCol = [.1 .1 .1 ; .1 .1 .1]; %[Hold ; Respond]
Stm.FixRemoveOnGo = true;
Stm.FixWinSize = [1.5 1.5];

% Fixation position can be toggled with 1-5 keys --------------------------
Stm.Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm.Position{2} = [-5 -5]; % deg from center (-=left/down)
Stm.Position{3} = [+5 -5]; % deg from center (-=left/down)
Stm.Position{4} = [-5 +5]; % deg from center (-=left/down)
Stm.Position{5} = [+5 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm.CyclePosition = 0; % set zero for manual cycling
% Stm.Color = [0 1 0]; % [R G B] 0-1

%% Choice target stimuli ==================================================
TarCreateAlgorithm = 2;
% 1=manual / 2=algorithm single stim / 3=algorithm two stim

if TarCreateAlgorithm == 1
    % Manual target settings //////////////////////////////////////////
    Stm.RandomizeCond=true;
    Stm.nRepeatsStimSet=2;
    
    % shapes: 'circle','square','diamond'
    % maximum of 2 targets per stimulus
    %--- Condition 1 -----
    c=1;
    Stm.Cond(c).Targ(1).Shape = 'circle';
    Stm.Cond(c).Targ(1).Size = 3; % diameter in deg
    Stm.Cond(c).Targ(1).WinSize = 4; % deg
    Stm.Cond(c).Targ(1).Position = [-5 0]; % deg
    Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
    Stm.Cond(c).Targ(1).Color = [1 0 0]; % RGB 0-1
    Stm.Cond(c).Targ(1).Reward = 0.04;
    
    % Stm.Cond(c).Targ(2).Shape = 'circle';
    % Stm.Cond(c).Targ(2).Size = 3; % diameter in deg
    % Stm.Cond(c).Targ(2).WinSize = 4; % deg
    % Stm.Cond(c).Targ(2).Position = [+5 0]; % deg
    % Stm.Cond(c).Targ(2).Color = [1 0 0]; % RGB 0-1
    % Stm.Cond(c).Targ(2).Reward = 0.1;
    
    %--- Condition 2 -----
    % c=2;
    % Stm.Cond(c).Targ(1).Shape = 'diamond';
    % Stm.Cond(c).Targ(1).Size = 3; % diameter in deg
    % Stm.Cond(c).Targ(1).WinSize = 4; % deg
    % Stm.Cond(c).Targ(1).Position = [-3 -3]; % deg
    % Stm.Cond(c).Targ(1).Color = [1 1 0]; % RGB 0-1
    % Stm.Cond(c).Targ(1).Reward = 0.04;
    %
    % Stm.Cond(c).Targ(2).Shape = 'square';
    % Stm.Cond(c).Targ(2).Size = 2; % diameter in deg
    % Stm.Cond(c).Targ(2).WinSize = 4; % deg
    % Stm.Cond(c).Targ(2).Position = [3 -3]; % deg
    % Stm.Cond(c).Targ(2).Color = [0 1 1]; % RGB 0-1
    % Stm.Cond(c).Targ(2).Reward = 0.1;
elseif TarCreateAlgorithm == 2
    % Algorithm to create many conditions (single stim) ///////////////
    Stm.RandomizeCond=true;
    Stm.nRepeatsStimSet=10;
    
    % place stimuli on an imaginary circle around screen center
    Stm.PolarAngles = 0:10:3595 ; % deg
    %Stm.PolarAngles = [210*ones(1,1000) -30*ones(1,1000)]; % deg
    Stm.Eccentricity = 3.0; % deg
    
    x=Stm.Eccentricity.*cosd(Stm.PolarAngles);
    y=Stm.Eccentricity.*sind(Stm.PolarAngles);
    Stm.TarPos = [x' y'];
    
    for c=1:length(Stm.PolarAngles)
        Stm.Cond(c).Targ(1).Shape = 'circle';
        Stm.Cond(c).Targ(1).Size = 2; % diameter in deg
        Stm.Cond(c).Targ(1).WinSize = 2; % deg
        Stm.Cond(c).Targ(1).Position = Stm.TarPos(c,:); % deg
        Stm.Cond(c).Targ(1).PreTargCol = [0.45 0.45 0.45];
        Stm.Cond(c).Targ(1).Color = [.1 .1 .1]; % RGB 0-1
        Stm.Cond(c).Targ(1).Reward = 0.120;
    end
elseif TarCreateAlgorithm == 3
    % Algorithm to create many conditions (two stim) //////////////////
    Stm.RandomizeCond=true;
    Stm.nRepeatsStimSet=10;
    
    % place stimuli on an imaginary circle around screen center
    Stm.PolarAngles = 0:5:3595; % rad
    Stm.Eccentricity = 3.5; % deg
    
    x=Stm.Eccentricity.*cosd(Stm.PolarAngles);
    y=Stm.Eccentricity.*sind(Stm.PolarAngles);
    Stm.TarPos = [x' y'];
    
    for c=1:length(Stm.PolarAngles)
        Stm.Cond(c).Targ(1).Shape = 'circle';
        Stm.Cond(c).Targ(1).Size = 2; % diameter in deg
        Stm.Cond(c).Targ(1).WinSize = 2; % deg
        Stm.Cond(c).Targ(1).Position = Stm.TarPos(c,:); % deg
        Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
        %Stm.Cond(c).Targ(1).Color = [0 0.6 0]; % RGB 0-1
        Stm.Cond(c).Targ(1).Color = 0.5 + rand(1,3)/2; % RGB 0-1
        Stm.Cond(c).Targ(1).Reward = 0.050;
        
        Stm.Cond(c).Targ(2) = Stm.Cond(c).Targ(1);
        Stm.Cond(c).Targ(2).Position = -Stm.TarPos(c,:); % deg
    end
end

%% ========================================================================
Stm.LogFolder = 'C:\Users\NINuser\Documents\Log_CK\ChoiceSaccade';

% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;