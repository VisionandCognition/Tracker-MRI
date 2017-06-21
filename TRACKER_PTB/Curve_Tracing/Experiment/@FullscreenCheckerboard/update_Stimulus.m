function update_UpdateStimulus(obj, lft)
global Log;

    
    %% fullscreen checkerboard
%     if lft < obj.startTrial+obj.taskParams.RetMap.PreDur
%         obj.updateState(obj.PRE, time);
%         IsPre = true;
%         IsOn = false;
%         IsOff = false;
%         IsPost = false;
%         if ~PreStarted
%             PreStarted = true;
%             CheckStartLogged = false;
%             Log.CheckerON=[];
%             Log.CheckerOFF=[];
%             CheckStartLogged=false;
%             CheckStopLogged=false;
%             ChkNum = 1;
%         end
%         WasPreDur=true;
%         obj.drawChecker = false;
%     elseif mod(lft-obj.startTrial-obj.taskParams.RetMap.PreDur,...
%             sum(obj.taskParams.RetMap.Checker.OnOff)) <= ...
%             obj.taskParams.RetMap.Checker.OnOff(1) && ...
%             lft < obj.startTrial + obj.taskParams.RetMap.PreDur + ...
%             sum(obj.taskParams.RetMap.Checker.OnOff)*obj.taskParams.RetMap.nCycles
%         
%         
%         %obj.updateState(obj.ON, time);
%         IsPre = false;
%         IsOn = true;
%         IsOff = false;
%         IsPost = false;
%         if ~OnStarted
%             OnStarted=true;
%             OffStarted=false;
%             Log.CheckerON = [Log.CheckerON; lft];
%             Log.nEvents=Log.nEvents+1;
%             Log.Events(Log.nEvents).type='StimON';
%             Log.Events(Log.nEvents).t=lft-Par.ExpStart;
%             Log.Events(Log.nEvents).StimName = Stm(STIMNR).Descript;
%             CheckStartLogged = true;
%             CheckStopLogged =false;
%         end
%         if WasPreDur % coming out of predur
%             Par.FixInOutTime=[Par.FixInOutTime;0 0];
%             WasPreDur=false;
%         end
%         if nCyclesDone < obj.taskParams.RetMap.nCycles || ...
%                 ~obj.taskParams.RetMap.nCycles
%             obj.drawChecker = true;
%             if nCyclesDone > 0 && nCyclesReported < nCyclesDone
%                 %output fixation statistics
%                 if Par.FixStatToCMD
%                     fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
%                         sprintf('%0.1f',...
%                         100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
%                         '%%, Run: ' ...
%                         sprintf('%0.1f',...
%                         100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
%                         '%%\n']);
%                     Par.FixInOutTime = [Par.FixInOutTime;0 0];
%                     nCyclesReported=nCyclesReported+1;
%                 end
%             end
%         end
%     elseif mod(lft-obj.startTrial-obj.taskParams.RetMap.PreDur,...
%             sum(obj.taskParams.RetMap.Checker.OnOff)) <= ...
%             obj.taskParams.RetMap.Checker.OnOff(1) && ...
%             lft >= obj.startTrial + obj.taskParams.RetMap.PreDur + ...
%             sum(obj.taskParams.RetMap.Checker.OnOff)*obj.taskParams.RetMap.nCycles && ...
%             ~PostStarted
%         
%         obj.updateState('Post', time);
%         IsPre = false;
%         IsOn = false;
%         IsOff = false;
%         IsPost = true;
%         if ~PostStarted
%             PostStarted=true;
%             Log.StartPostDur=lft;
%             Log.nEvents=Log.nEvents+1;
%             Log.Events(Log.nEvents).type='PostDurStart';
%             Log.Events(Log.nEvents).t=Log.StartPostDur-Par.ExpStart;
%             Log.Events(Log.nEvents).StimName = [];
%             obj.obj.drawChecker = false;
%             if nCyclesDone > 0 && nCyclesReported < nCyclesDone
%                 %output fixation statistics
%                 if Par.FixStatToCMD
%                     fprintf(['Fix perc. cycle ' num2str(nCyclesDone) ': ' ...
%                         sprintf('%0.1f',...
%                         100*(Par.FixInOutTime(end,1)/sum(Par.FixInOutTime(end,:)))) ...
%                         '%%, Run: ' ...
%                         sprintf('%0.1f',...
%                         100*(sum(Par.FixInOutTime(2:end,1))/sum(sum(Par.FixInOutTime(2:end,:))))) ...
%                         '%%\n']);
%                     Par.FixInOutTime = [Par.FixInOutTime;0 0];
%                     nCyclesReported=nCyclesReported+1;
%                 end
%             end
%         end
%     elseif lft >= obj.startTrial + obj.taskParams.RetMap.PreDur + ...
%             sum(obj.taskParams.RetMap.Checker.OnOff)*obj.taskParams.RetMap.nCycles + ...
%             obj.taskParams.RetMap.PostDur
%         RunEnded = true;
%         Log.nEvents=Log.nEvents+1;
%         Log.Events(Log.nEvents).type='RunStop';
%         Log.Events(Log.nEvents).t=lft-Par.ExpStart;
%         Log.Events(Log.nEvents).StimName = [];
%     end
end