function fixChange = CheckTracker
% check and update eye info in tracker window

global Par;

    if Par.TestRunstimWithoutDAS
        if ~Par.FixIn
            fixChange = true;
            Par.FixIn = true;
        else
            fixChange = false;
        end
    else
        dasrun(5);
        [fixChange, ~] = DasCheck;
        fixChange = fixChange ~= 0;
    end
end