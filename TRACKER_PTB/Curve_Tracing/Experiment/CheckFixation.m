function CheckFixation
% Check if eye enters fixation window =============================

global Par;
global Log;
global StimObj;

Stm = StimObj.Stm;

    
    if ~Par.FixIn %not fixating
        if ~Par.CheckFixIn && ~Par.TestRunstimWithoutDAS
            dasreset(0); % start testing for eyes moving into fix window
        end
        Par.CheckFixIn=true;
        Par.CheckFixOut=false;
        Par.CheckTarget=false;

        % Load retinotopic mapping stimuli - none to load
        LoadStimuli=false;

        % Check eye position
        fixChange = CheckTracker;

        if fixChange % eye in fix window (hit will never be 1 is tested without DAS)
            Par.FixIn=true;
            Par.LastFixInTime=GetSecs;
            Stm(1).task.fixation_in(Par.LastFixInTime);

            % Par.Trlcount=Par.Trlcount+1;
            refreshtracker(3);
        end
        if mod(Par.nf,100)==0 && ~Par.TestRunstimWithoutDAS
            refreshtracker(1);
             Par.nf = Par.nf + 1;
        end
    end
    % Check if eye leaves fixation window =============================
    if Par.FixIn %fixating
        if ~Par.CheckFixOut && ~Par.TestRunstimWithoutDAS
            dasreset(1); % start testing for eyes leaving fix window
        end
        Par.CheckFixIn=false;
        Par.CheckFixOut=true;
        Par.CheckTarget=false;

        % Check eye position
        % DasCheck
        fixChange = CheckTracker;

        if fixChange % eye out of fix window
            Par.FixIn=false;
            Par.LastFixOutTime=GetSecs;

            Stm(1).task.fixation_out(Par.LastFixOutTime);

            refreshtracker(1);

            Log.events.add_entry(Par.LastFixOutTime, Stm(1).task.name, 'Fixation', 'Out');
        end
    end
end