function falseResponseGiven(obj, lft)
    global Par
    global Log
    
    Par.RespValid = false;
    Par.CurrResponse = Par.RESP_FALSE;
    if ~Par.ResponseGiven && ~Par.FalseResponseGiven %only log once
        Par.Response(Par.CurrResponse)=Par.Response(Par.CurrResponse)+1;
        Par.ResponsePos(Par.CurrResponse)=Par.ResponsePos(Par.CurrResponse)+1;
        
        Log.Events.add_entry(lft, 'ResponseGiven', 'FALSE');
    end
    Par.FalseResponseGiven=true;
end