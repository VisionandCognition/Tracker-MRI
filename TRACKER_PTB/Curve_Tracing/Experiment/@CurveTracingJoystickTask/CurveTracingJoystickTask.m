classdef CurveTracingJoystickTask
    % CurveTracingTask The curve tracing task.
    properties (Constant)
        taskName = 'Curve tracing'
    end
    properties
        post_switch_joint_alpha = 1.0;
        stimuli_params;
        curr_stim_index = 0;
        curr_stim;
    end
    
    methods
        function obj = CurveTracingJoystickTask(csvfile)
            obj.stimuli_params = readtable(csvfile);
        end
        [Par, Stm] = update_Init(obj, Par, Stm);
        [Par, Stm] = update_PrepareStim(obj, Par, Stm);
        [Par, Stm] = update_PreOrPostSwitch(obj, Par, Stm);
        
        drawFix(obj, Stm);
        drawNoiseOnly(obj, Stm);
        drawCurve(obj, pos, connection1, connection2, indpos, Par, Stm);
        
        function [Par, Stm] = updateAndDraw(obj, State, Par, Stm)
            switch State
                case 'PREPARE_STIM'
                    [Par, Stm] = obj.update_PrepareStim(Par, Stm);
                case 'INIT'
                    [Par, Stm] = obj.update_Init(Par, Stm);
                case 'PREFIXATION'
                    [Par, Stm] = obj.update_Prefixation(Par, Stm);
                case 'PRESWITCH'
                    [Par, Stm] = obj.update_PreOrPostSwitch(Par, Stm);
                case 'SWITCHED'
                    [Par, Stm] = obj.update_PreOrPostSwitch(Par, Stm);
                case 'POSTSWITCH'
                    [Par, Stm] = obj.update_PreOrPostSwitch(Par, Stm);
                otherwise
                    print State
            end
        end
        function [Par, Stm] = update_Prefixation(obj, Par, Stm)
        end

        function [Par, Stm] = RandomizePawIndOffset(obj, Par, Stm)
            % Perform stratisfied repetitions
            % size(Stm(1).PawIndPositions,1) is used to allow right or left
            % branch to appear when there are only 2 targets
            Group_pos = reshape(...
                repmat(randperm(size(Stm(1).PawIndPositions,1)/2, Stm(1).NumOfPawIndicators/2),...
                       2,1),...
                [1,Stm(1).NumOfPawIndicators]);
            Group_pos = (Group_pos-1) * 2;
            ind = zeros(size(Group_pos));
            angles = zeros(size(Group_pos));
            for m = 1:Stm(1).NumOfPawIndicators/2
                ind(2*m-1:2*m) = randperm(2);

                a = min(Stm(1).CurveAnglesAtFP(m,:));
                b = max(Stm(1).CurveAnglesAtFP(m,:));
                angles(2*m-1:2*m) = (b-a).*rand(1,1) + a;
            end
            Stm(1).PawIndOffsetPix = Stm(1).PawIndPositions(...
                Group_pos + ind, :) * Par.PixPerDeg;
            Par.CurveAngles = angles(Group_pos + ind);
    %             Stm(1).PawIndOffsetPix = Stm(1).PawIndPositions(...
    %                 randperm(size(Stm(1).PawIndPositions, 1), ...
    %                          Stm(1).NumOfPawIndicators), :) * Par.PixPerDeg;

            Par.DistractLineTarget = randperm(2);
        end
    end
    methods(Static)
    end
    
end
