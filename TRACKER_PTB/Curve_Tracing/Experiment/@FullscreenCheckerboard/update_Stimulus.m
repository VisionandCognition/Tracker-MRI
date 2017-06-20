function update_UpdateStimulus(obj)
    if DispChecker % coarse checkerboard
            %% fullscreen checkerboard
            if lft < Log.StartBlock+Stm(STIMNR).RetMap.PreDur
                IsPre = true;
                IsOn = false;
                IsOff = false;
                IsPost = false;
                if ~PreStarted
                    PreStarted = true;
                    CheckStartLogged = false;
                    Log.CheckerON=[];
                    Log.CheckerOFF=[];
                    CheckStartLogged=false;
                    CheckStopLogged=false;
                    ChkNum = 1;
                end
                WasPreDur=true;
                DrawChecker = false;
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur,...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles
                IsPre = false;
                IsOn = true;
                IsOff = false;
                IsPost = false;
                if ~OnStarted
                    OnStarted=true;
                    OffStarted=false;
                    Log.CheckerON = [Log.CheckerON; lft];
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='StimON';
                    Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
                    CheckStartLogged = true;
                    CheckStopLogged =false;
                end
                if WasPreDur % coming out of predur
                    Par.FixInOutTime=[Par.FixInOutTime;0 0];
                    WasPreDur=false;
                end
                if nCyclesDone < Stm(STIMNR).RetMap.nCycles || ...
                        ~Stm(STIMNR).RetMap.nCycles
                    DrawChecker = true;
                    if nCyclesDone > 0 && nCyclesReported < nCyclesDone
                        %output fixation statistics
                        if Par.FixStatToCMD
                            fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
                                sprintf('%0.1f',...
                                100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
                                '%%, Run: ' ...
                                sprintf('%0.1f',...
                                100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
                                '%%\n']);
                            Par.FixInOutTime = [Par.FixInOutTime;0 0];
                            nCyclesReported=nCyclesReported+1;
                        end
                    end
                end
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur-Stm(STIMNR).RetMap.Checker.OnOff(1),...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft < Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles
                IsPre = false;
                IsOn = false;
                IsOff = true;
                IsPost = false;
                if ~OffStarted
                    OffStarted=true;
                    OnStarted=false;
                    Log.CheckerOFF = [Log.CheckerOFF; lft];
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='StimOFF';
                    Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
                    nCyclesDone=nCyclesDone+1;
                    CheckStartLogged = false;
                    CheckStopLogged =true;
                end
                DrawChecker = false;
            elseif mod(lft-Log.StartBlock-Stm(STIMNR).RetMap.PreDur,...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)) <= ...
                    Stm(STIMNR).RetMap.Checker.OnOff(1) && ...
                    lft >= Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles && ...
                    ~PostStarted
                IsPre = false;
                IsOn = false;
                IsOff = false;
                IsPost = true;
                if ~PostStarted
                    PostStarted=true;
                    Log.StartPostDur=lft;
                    Log.nEvents=Log.nEvents+1;
                    Log.Events(Log.nEvents).type='PostDurStart';
                    Log.Events(Log.nEvents).t=Log.StartPostDur-Par.ExpStart;
                    Log.Events(Log.nEvents).StimName = [];
                    DrawChecker = false;
                    if nCyclesDone > 0 && nCyclesReported < nCyclesDone
                        %output fixation statistics
                        if Par.FixStatToCMD
                            fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
                                sprintf('%0.1f',...
                                100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
                                '%%, Run: ' ...
                                sprintf('%0.1f',...
                                100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
                                '%%\n']);
                            Par.FixInOutTime = [Par.FixInOutTime;0 0];
                            nCyclesReported=nCyclesReported+1;
                        end
                    end
                end
            elseif lft >= Log.StartBlock + Stm(STIMNR).RetMap.PreDur + ...
                    sum(Stm(STIMNR).RetMap.Checker.OnOff)*Stm(STIMNR).RetMap.nCycles + ...
                    Stm(STIMNR).RetMap.PostDur
                RunEnded = true;
                Log.nEvents=Log.nEvents+1;
                Log.Events(Log.nEvents).type='RunStop';
                Log.Events(Log.nEvents).t=lft-Par.ExpStart;
                Log.Events(Log.nEvents).StimName = [];
            end
    end
end