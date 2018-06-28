function checkResponses(obj, time)
    global Par;
    global Log;
    if strcmp(obj.state, 'PREFIXATION')
        if time > obj.stateStart.PREFIXATION + obj.taskParams.prefixPeriod/1000 && ...
                (Par.FixIn || (~Par.WaitForFixation || ~Par.WaitForFixation_phase(1)))
            obj.updateState('FIXATION_PERIOD', time);
            obj.startTrackingFixationTime(time, Par.FixIn);
        end
    end
    if strcmp(obj.state, 'FIXATION_PERIOD')
        if time > obj.stateStart.FIXATION_PERIOD + obj.taskParams.fixationPeriod/1000
            obj.updateState('POSTFIXATION', time);
            obj.stopTrackingFixationTime(time);

            fixInRatio = obj.fixation_ratio();

            if Par.Verbosity >= 2
                fprintf('Fixation ratio: %0.2f  (in: %0.1f, out: %0.1f)\n', fixInRatio, ...
                    obj.time_fixating(), obj.time_not_fixating());
            end

            if fixInRatio >= 0.90
                RewardAmount = Par.GiveRewardAmount + ...
                    fixInRatio^2 * Par.RewardTime * obj.taskParams.rewardMultiplier;

                obj.curr_response = 'correct';
                Par.CurrResponse = Par.RESP_CORRECT;

                Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;

                Par.GiveRewardAmount = Par.GiveRewardAmount + RewardAmount;
                Log.events.add_entry(time, obj.taskName, 'ResponseGiven', 'CORRECT');
                Log.events.add_entry(time, obj.taskName, 'ResponseReward', num2str(RewardAmount));
            else
                obj.curr_response = 'break_fix';
                Par.CurrResponse = Par.RESP_BREAK_FIX;
            end
        end
    end
    if strcmp(obj.state, 'POSTFIXATION')
        if time > obj.stateStart.POSTFIXATION + obj.taskParams.postfixPeriod/1000
            obj.responses.(obj.curr_response) = obj.responses.(obj.curr_response) + 1;
            
            obj.incrementSubtrial();
            
            % if iSubtrial == 0, then end of trial
            if obj.iSubtrial > 0 % obj.iTrialOfBlock < obj.param('BlockSize')
                obj.set_param('FixationPeriodTime', ...
                    obj.taskParams.EventPeriods(1)/1000 + ...
                    rand(1)*obj.taskParams.EventPeriods(2)/1000);

                obj.updateState('FIXATION_PERIOD', time);
                obj.startTrackingFixationTime(time, Par.FixIn);
            else
                obj.updateState('TRIAL_END', time);
            end
        end
    end
end