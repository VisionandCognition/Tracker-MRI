function CheckKeys
% check for key-presses

global Par;
global Log;
global StimObj;

Stm = StimObj.Stm;

    % check
    [Par.KeyIsDown,Par.KeyTime,KeyCode]=KbCheck; %#ok<*ASGLU>

    % interpret
    if Par.KeyIsDown && ~Par.KeyWasDown
        Key=KbName(KbName(KeyCode));
        if isscalar(KbName(KbName(KeyCode)))
            % The MRI trigger is the only key that can be sent outside
            % of tracker window
            if Key == Par.KeyTriggerMR
                Log.MRI.TriggerReceived = true;
                Log.MRI.TriggerTime = ...
                    [Log.MRI.TriggerTime; Par.KeyTime];
                Log.events.add_entry(Par.KeyTime, 'NA', 'MRI_Trigger', 'Received');
                
                if isfield(Par, 'exitOnKeyWaitForMRITrigger') && ...
                        Par.exitOnKeyWaitForMRITrigger
                    fprintf('\n MRI Trigger Received Early!!!\n');
                    Par.ESC = true;
                    Log.events.add_entry(GetSecs, ...
                        Stm(1).task.name, ...
                        'MRI_Trigger', 'Received_Before_Ready');
                end
            elseif Par.KeyDetectedInTrackerWindow || Par.TestRunstimWithoutDAS % only in Tracker
                switch Key
                    case Par.KeyEscape % Never caught - caught by tracker?
                        fprintf('\n ------------- Escape Key Received!\n');
                        Par.ESC = true;
                    case Par.KeyTriggerMR
                        % cannot be executed
                    case Par.KeyWaitForMRITrigger
                        if isfield(Par, 'exitOnKeyWaitForMRITrigger') && ...
                                Par.exitOnKeyWaitForMRITrigger
                            fprintf('\n ------------- WaitForMRITrigger Key Received!\n');
                            Par.ESC = true;
                            Log.events.add_entry(GetSecs, ...
                                ['PreTrigger' Stm(1).task.name], ...
                                'KeyPressed', 'KeyWaitForMRITrigger');
                        end
                    case Par.KeyCountDownMRITriger
                        if isfield(Par, 'exitOnKeyWaitForMRITrigger') && ...
                                Par.exitOnKeyWaitForMRITrigger && isinf(Par.noNewTrialsAfter)
                            fprintf('\n ------------- Count down to MRI Trigger!\n');
                            Log.events.add_entry(GetSecs, ...
                                ['PreTrigger' Stm(1).task.name], ...
                                'KeyPressed', 'CountDownToMRITrigger');
                            Par.noNewTrialsAfter = GetSecs + 5;
                        end
                    case Par.KeyFORPResponseLeft
                        Par.ForpRespLeft=true;
                        Log.events.add_entry(GetSecs, Stm(1).task.name, 'FORPResponse_Initiate', 'Left');
                        
                    case Par.KeyFORPResponseRight
                        Par.ForpRespRight=false;
                        Log.events.add_entry(GetSecs, Stm(1).task.name, 'FORPResponse_Initiate', 'Right');
                    case Par.KeyJuice
                        Par.ManualReward = true;
                        Log.ManualRewardTime = ...
                            [Log.ManualRewardTime; Par.KeyTime];
                    case Par.KeyCyclePos
                        if Par.ToggleCyclePos
                            Par.ToggleCyclePos = false;
                            fprintf('Toggle position cycling: OFF\n');
                        else
                            Par.ToggleCyclePos = true;
                            fprintf('Toggle position cycling: ON\n');
                        end
                    case Par.Key1
                        Par.SwitchPos = true;
                        Par.WhichPos = '1';
                    case Par.Key2
                        Par.SwitchPos = true;
                        Par.WhichPos = '2';
                    case Par.Key3
                        Par.SwitchPos = true;
                        Par.WhichPos = '3';
                    case Par.Key4
                        Par.SwitchPos = true;
                        Par.WhichPos = '4';
                    case Par.Key5
                        Par.SwitchPos = true;
                        Par.WhichPos = '5';
                    case Par.KeyNext
                        Par.SwitchPos = true;
                        Par.WhichPos = 'Next';
                        %                 case Par.KeyPrevious
                        %                     Par.SwitchPos = true;
                        %                     Par.WhichPos = 'Prev';
                    case Par.KeyRequireFixation
                        time = GetSecs;
                        if ~Par.RequireFixationForReward;
                            Par.RequireFixationForReward = true;
                            Par.WaitForFixation = true;
                            fprintf('Requiring fixation for reward.\n')
                            Log.events.add_entry(time, Stm(1).task.name, 'FixationRequirement', 'Start');
                        else
                            Par.RequireFixationForReward = false;
                            Par.WaitForFixation = false;
                            fprintf('Not requiring fixation for reward.\n')
                            Log.events.add_entry(time, Stm(1).task.name, 'FixationRequirement', 'Stop');
                        end
                end
            end
            Par.KeyWasDown=true;
        end
    elseif Par.KeyIsDown && Par.KeyWasDown
        Par.SwitchPos = false;
    elseif ~Par.KeyIsDown && Par.KeyWasDown
        % key is released
        Par.KeyWasDown = false;
        Par.SwitchPos = false;
    end
    % reset to false
    Par.KeyDetectedInTrackerWindow=false;
end