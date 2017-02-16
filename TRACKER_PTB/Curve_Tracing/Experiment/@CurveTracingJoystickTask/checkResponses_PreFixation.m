function checkResponses_PreFixation( obj, lft )
%CHECKRESPONSES_PREFIXATION Helper function for CheckResponses.

    global Par;

    if Par.FixIn
        obj.updateState('FIXATING', lft);
        obj.updateState('PRESWITCH', lft);
    end
end

