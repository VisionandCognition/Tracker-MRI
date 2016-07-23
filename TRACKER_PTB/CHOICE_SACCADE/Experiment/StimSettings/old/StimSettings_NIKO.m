%StimSettings
global StimObj

%% Background -------------------------------------------------------------
Stm.BackColor = [.25 .25 .25]; % [R G B] 0-1

%% Timing -----------------------------------------------------------------
% pre-defined in ParSettings at init: will be overwritten with these values
Stm.PreFixT = 2000; % time to enter fixation window
Stm.FixT = 1000; % time to fix before stim onset
Stm.KeepFixT = 200; % time to fix before target onset.
Stm.ReacT = 500; % max allowed reaction time (leave fixwin after target onset)
Stm.StimT = Stm.KeepFixT + Stm.ReacT; % stimulus display duration
Stm.SaccT = 500; % max allowed saccade time (from leave fixwin to enter target win)
Stm.ErrT = 500; % punishment extra ISI after error trial (there are no error trials here)
Stm.ISI = 1000; % base inter-stimulus interval
Stm.ISI_RAND = 200; % maximum extra (random) ISI to break any possible rythm

%% Fixation ---------------------------------------------------------------
%NB! may be overruled in the parsettings file
%Stm.FixWinSize = [10 10]; % [W H] in deg 
%NB! may be overruled in the parsettings file

Stm.FixDotSize = 0.15;
Stm.FixDotCol = [1 0 0 ; 1 0 0]; %[Hold ; Respond]
Stm.FixRemoveOnGo = true;
Stm.FixWinSize = [1.4 1.4];

% Fixation position can be toggled with 1-5 keys --------------------------
Stm.Position{1} = [0 0]; % deg from center [vert hor] (-=left/down)
Stm.Position{2} = [-5 -5]; % deg from center (-=left/down)
Stm.Position{3} = [+5 -5]; % deg from center (-=left/down)
Stm.Position{4} = [-5 +5]; % deg from center (-=left/down)
Stm.Position{5} = [+5 +5]; % deg from center (-=left/down)

% Stimulus position can be cycled automatically every n-th trial
Stm.CyclePosition = 0; % set zero for manual cycling

%% Choice target stimuli ==================================================
for CreateTargets=1
    TarCreateAlgorithm = 3;
    % 1=manual / 2=algorithm single stim / 3=algorithm two stim
    
    if TarCreateAlgorithm == 1
        % Manual target settings //////////////////////////////////////////
        for ManualTargets=1
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
            % Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
            % Stm.Cond(c).Targ(1).Color = [1 1 0]; % RGB 0-1
            % Stm.Cond(c).Targ(1).Reward = 0.04;
            %
            % Stm.Cond(c).Targ(2).Shape = 'square';
            % Stm.Cond(c).Targ(2).Size = 2; % diameter in deg
            % Stm.Cond(c).Targ(2).WinSize = 4; % deg
            % Stm.Cond(c).Targ(2).Position = [3 -3]; % deg
            % Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
            % Stm.Cond(c).Targ(2).Color = [0 1 1]; % RGB 0-1
            % Stm.Cond(c).Targ(2).Reward = 0.1;
        end
    elseif TarCreateAlgorithm == 2
        % Algorithm to create many conditions (single stim) ///////////////
        for AlgoTargets=1
            Stm.RandomizeCond=true;
            Stm.nRepeatsStimSet=30;
            
            % place stimuli on an imaginary circle around screen center
            %Stm.PolarAngles = 0:10:3595 ; % deg
%             Stm.PolarAngles = [-22.5*ones(1,1000) -45*ones(1,1000) -67.5*ones(1,1000) ...
%                 -90*ones(1,1000) -112.5*ones(1,1000) -135*ones(1,1000) -157.5*ones(1,1000) ]; % deg
            Stm.PolarAngles = 0:45:3595 ; % deg
            Stm.Eccentricity = 3; % deg
            
            x=Stm.Eccentricity.*cosd(Stm.PolarAngles);
            y=Stm.Eccentricity.*sind(Stm.PolarAngles);
            Stm.TarPos = [x' y'];
            
            for c=1:length(Stm.PolarAngles);
                Stm.Cond(c).Targ(1).Shape = 'circle';
                Stm.Cond(c).Targ(1).Size = 2; % diameter in deg
                Stm.Cond(c).Targ(1).WinSize = 2; % deg
                Stm.Cond(c).Targ(1).Position = Stm.TarPos(c,:); % deg
                Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
                Stm.Cond(c).Targ(1).Color = [1 0 0]; % RGB 0-1
                Stm.Cond(c).Targ(1).Reward = 0.150;
            end
        end
    elseif TarCreateAlgorithm == 3
        % Algorithm to create many conditions (two stim) //////////////////
        for AlgoTargets=1
            Stm.RandomizeCond=true;
            Stm.nRepeatsStimSet=5;
            
            % place stimuli on an imaginary circle around screen center
            Stm.PolarAngles = 0:5:3595; % rad
            Stm.Eccentricity = 3.5; % deg
            
            x=Stm.Eccentricity.*cosd(Stm.PolarAngles);
            y=Stm.Eccentricity.*sind(Stm.PolarAngles);
            Stm.TarPos = [x' y'];
            
            for c=1:length(Stm.PolarAngles);
                Stm.Cond(c).Targ(1).Shape = 'circle';
                Stm.Cond(c).Targ(1).Size = 2; % diameter in deg
                Stm.Cond(c).Targ(1).WinSize = 2.5; % deg
                Stm.Cond(c).Targ(1).Position = Stm.TarPos(c,:); % deg
                Stm.Cond(c).Targ(1).PreTargCol = [0.27 0.27 0.27];
                %Stm.Cond(c).Targ(1).Color = [0 0.6 0]; % RGB 0-1
                Stm.Cond(c).Targ(1).Color = 0.5+0.5.*rand(1,3); % RGB 0-1
                Stm.Cond(c).Targ(1).Reward = 0.250;
                
                Stm.Cond(c).Targ(2) = Stm.Cond(c).Targ(1);
                Stm.Cond(c).Targ(2).Position = -Stm.TarPos(c,:); % deg
            end
        end
    end
end

%% ========================================================================
% Write stimulus settings to global variable StimObj
StimObj.Stm = Stm;