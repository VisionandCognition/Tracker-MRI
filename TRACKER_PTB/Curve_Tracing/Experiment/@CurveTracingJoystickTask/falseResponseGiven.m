function falseResponseGiven(obj, lft)
    global Par
    global Log
    
    Par.RespValid = false;
    obj.curr_response = 'false';
    Par.CurrResponse = Par.RESP_FALSE;
    obj.curr_hand = Par.NewResponse; % save which hand
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;        
        Log.events.add_entry(lft, obj.taskName, 'ResponseGiven', 'INCORRECT');
    end
    Par.FalseResponseGiven=true;
end