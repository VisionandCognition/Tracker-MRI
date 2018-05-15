function falseResponseGiven(obj, lft)
    global Par
    global Log
    
    Par.RespValid = false;
    obj.curr_response = 'false';
    Par.CurrResponse = Par.RESP_FALSE;

    if isfield(Par, 'FeedbackSound') && isfield(Par, 'FeedbackSoundPar') && ...
            Par.FeedbackSound(Par.CurrResponse) && ...
            all(~isnan(Par.FeedbackSoundPar(Par.CurrResponse,:)))
        if Par.FeedbackSoundPar(Par.CurrResponse)
            try
                PsychPortAudio('Start', ...
                    Par.FeedbackSoundSnd(Par.CurrResponse).h, 1, 0, 1);
            catch
            end
        end
    end

    obj.curr_hand = Par.NewResponse; % save which hand
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;        
        Log.events.add_entry(lft, obj.taskName, 'ResponseGiven', 'INCORRECT');
    end
    Par.FalseResponseGiven=true;
end