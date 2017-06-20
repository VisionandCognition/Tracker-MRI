function drawStimuli(obj)
%% change the checkerboard contrast if required
    if DrawChecker
        if TrackingCheckerContChange
            if lft-tLastCheckerContChange >= ...
                    1/Stm(1).RetMap.Checker.FlickFreq_Approx;
                if ChkNum==1;
                    ChkNum=2;
                elseif ChkNum==2
                    ChkNum=1;
                end
                tLastCheckerContChange=lft;
            end
        else
            tLastCheckerContChange=lft;
            TrackingCheckerContChange=true;
        end
    end
end