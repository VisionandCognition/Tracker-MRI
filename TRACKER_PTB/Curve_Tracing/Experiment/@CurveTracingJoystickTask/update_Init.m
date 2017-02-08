function [Par, Stm] = update_Init(obj, Par, Stm)
    % Allow for task to be changed
    Stm(1).PawIndSizePix = round(Stm(1).PawIndSize.*Par.PixPerDeg);
    Stm(1).FixTargetSizePix = round(1.25*Stm(1).FixDotSize*Par.PixPerDeg);

    % Chance of changing sides
    if Par.PawSides(1)==1 % currently left side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToRPawProb(2))

            Par.PawSides(1) = 2; % switch to right

            if Stm(1).NumOfPawIndicators > 1
                Par.PawSides(2:end) = 0;
                % Paw indicator 2 should be opposite of 1
                Par.PawSides(2) = mod(Par.PawSides(1),2)+1;
                % others can choose randomly
                for i = 2:Stm(1).NumOfPawIndicators/2
                    Par.PawSides(2*i-1:2*i) = randperm(2);
                end
            end

            Par.SwitchableInNumTrials = Stm(1).TrialsWithoutSwitching;
        end
    else % currently right side
        if Par.SwitchableInNumTrials <= 0 && (...
                Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(1) || ...
                ~Par.CorrectThisTrial && rand() <= Stm(1).SwitchToLPawProb(2))

            Par.PawSides(1) = 1; % switch to left

            if Stm(1).NumOfPawIndicators > 1
                Par.PawSides(2:end) = 0;
                % Paw indicator 2 should be opposite of 1
                Par.PawSides(2) = mod(Par.PawSides(1),2)+1;
                % others can choose randomly
                for i = 2:Stm(1).NumOfPawIndicators/2
                    Par.PawSides(2*i-1:2*i) = randperm(2);
                end
            end
        end
    end
    Par.PartConnectedTarget = randperm(2, 1)+2;
    if Par.CorrectThisTrial || Par.TaskSwitched

        min_alpha = min(Stm(1).UnattdAlpha);
        max_alpha = max(Stm(1).UnattdAlpha);

        % Alpha (opacity) of distractor
        Par.unattended_alpha = (max_alpha-min_alpha)*rand() + min_alpha;
        Par.unattended_alpha = min(1.0, Par.unattended_alpha);
        Par.unattended_alpha = max(0.0, Par.unattended_alpha);


        min_alpha = min(Stm(1).AlphaPreSwitch);
        max_alpha = max(Stm(1).AlphaPreSwitch);
        Par.trial_preswitch_alpha = (max_alpha-min_alpha)*rand() + min_alpha;
        Par.trial_preswitch_alpha = min(1.0, Par.trial_preswitch_alpha);
        Par.trial_preswitch_alpha = max(0.0, Par.trial_preswitch_alpha);
    end
    Par.TaskSwitched = false;
    Par.PawWrongSide=mod(Par.PawSides(1),2)+1;

    obj.RandomizePawIndOffset(Par, Stm);
    min_alpha = min(Stm(1).PostSwitchJointAlpha);
    max_alpha = max(Stm(1).PostSwitchJointAlpha);
    obj.post_switch_joint_alpha = rand()*(...
        max_alpha - min_alpha) + min_alpha;
    obj.post_switch_joint_alpha = min(1, max(0, obj.post_switch_joint_alpha));
end 