function checkResponses_PreFixation( obj, lft )
%CHECKRESPONSES_PREFIXATION Helper function for CheckResponses.

    global Par;
    global Log;

    if Par.FixIn || ~Par.WaitForFixation
        % The subject "should" be fixating now, start tracking time
        obj.fixationTrackStarted = true;
        Log.Events.add_entry(lft, 'FixationTracking', 'Start');
        
        obj.trialFixS = 0.0; % seconds spent fixating in current trial
        obj.trialNoFixS = 0.0;

        if Par.FixIn
            obj.updateState('FIXATING', lft);
            obj.fixIn = true;
            obj.fixInTime = lft;
            obj.fixOutTime = nan;
        else
            obj.fixIn = false;
            obj.fixOutTime = lft;
            obj.fixInTime = nan;
        end
        obj.updateState('PRESWITCH', lft);
    end
end

