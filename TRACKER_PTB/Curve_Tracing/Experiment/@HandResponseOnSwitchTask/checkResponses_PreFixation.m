function checkResponses_PreFixation( obj, time )
%CHECKRESPONSES_PREFIXATION Helper function for CheckResponses.

    global Par;
    global Log;

    if time > obj.stateStart.PREFIXATION + obj.taskParams.prefixPeriod/1000 ...
            && (Par.FixIn || (~Par.WaitForFixation || ~Par.WaitForFixation_phase(1)))
        % The subject "should" be fixating now, start tracking time
        Log.events.add_entry(time, obj.taskName, 'FixationTracking', 'Start');

        obj.startTrackingFixationTime(time, Par.FixIn);
        obj.updateState('PRESWITCH', time);
    elseif ~Par.FixIn && (Par.WaitForFixation && Par.WaitForFixation_phase(1)) % if fixation lost, restart prefix period
        obj.updateState('PREFIXATION', time);
    end
end

