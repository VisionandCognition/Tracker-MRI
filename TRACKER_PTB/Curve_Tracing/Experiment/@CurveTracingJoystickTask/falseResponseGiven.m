function falseResponseGiven(obj, lft)
    global Par
    global Log
    
    Par.RespValid = false;
    obj.curr_response = 'false';
    Par.CurrResponse = Par.RESP_FALSE;
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        
        Log.events.add_entry(lft, obj.taskName, 'ResponseGiven', 'FALSE');
    end
    Par.FalseResponseGiven=true;
end