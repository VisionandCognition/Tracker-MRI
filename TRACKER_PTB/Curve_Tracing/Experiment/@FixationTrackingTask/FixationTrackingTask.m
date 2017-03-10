classdef FixationTrackingTask < handle
    %FIXATIONTRACKINGTASK A task that tracks the percent of time fixating.
    properties (Access = private)
        % Always log fixation, "tracking" here means calculating amount of
        % fix-in and fix-out time.
        fixationTrackStarted = false; % updated depending on state
        fixIn = nan; % is subject fixating? (since the last time it was updated)
        fixInStart = nan;
        fixOutStart = nan;
        trialFixS = 0.0; % seconds spent fixating in current trial
        trialNoFixS = 0.0; % seconds spent not fixating in current trial
    end
    methods (Access = protected)
        function startTrackingFixationTime(obj, time, fixIn)
            obj.fixationTrackStarted = time;
            
            obj.trialFixS = 0.0;
            obj.trialNoFixS = 0.0;
            if fixIn
                obj.fixIn = true;
                obj.fixInStart = time;
                obj.fixOutStart = nan;
            else
                obj.fixIn = false;
                obj.fixOutStart = time;
                obj.fixInStart = nan;
            end
        end
        function stopTrackingFixationTime(obj, time)
            if ~obj.fixationTrackStarted % already stopped
                return
            end
            obj.fixationTrackStarted = false;
            if obj.fixIn
                obj.trialFixS = obj.trialFixS + (time - obj.fixInStart);
                %fprintf('stop @%0.3f\t\t\t', time-obj.fixationTrackStarted)
                %fprintf('accum. in: %0.3f\n', obj.trialFixS);
            else
                obj.trialNoFixS = obj.trialNoFixS + (time - obj.fixOutStart);
                %fprintf('stop @%0.3f\t\t\t', time-obj.fixationTrackStarted)
                %fprintf('accum. out: %0.3f\n', obj.trialNoFixS);
            end
            obj.fixInStart = nan;
            obj.fixOutStart = nan;
            obj.fixIn = nan;
            
            global Par;
            %fprintf('stop tracking %0.3f\n', time-Par.ExpStart)
        end
    end
    methods (Abstract)
       name = name(obj) % return the name of the task (without "task")
    end
    methods
        function fixationRatio = fixation_ratio(obj)
            fixationRatio = obj.trialFixS / (obj.trialNoFixS + obj.trialFixS);
        end
        function fixInStart = time_fixating(obj)
            fixInStart = obj.trialFixS;
        end
        function fixOutStart = time_not_fixating(obj)
            fixOutStart = obj.trialNoFixS;
        end
        function fixation_in(obj, time)
            global Log;
        	Log.events.add_entry(time, obj.name(), 'Fixation', 'In');
            
            % function should only be called if previously not fixating
            %assert(isnan(obj.fixIn) || ~obj.fixIn);
            
            if obj.fixationTrackStarted
                obj.fixIn = true;
                obj.fixInStart = time;
                assert(~isnan(obj.fixOutStart))
                
                obj.trialNoFixS = obj.trialNoFixS + (obj.fixInStart - obj.fixOutStart);
                %fprintf('fix in @%0.3f\t\t\t', time-obj.fixationTrackStarted)
                %fprintf('accum. out: %0.3f\n', obj.trialNoFixS);
            end
        end
        function fixation_out(obj, time)
            global Log;
        	Log.events.add_entry(time, obj.name, 'Fixation', 'Out');
            
            % function should only be called if previously fixating
            %assert(isnan(obj.fixIn) || obj.fixIn);
            
            if obj.fixationTrackStarted
                obj.fixIn = false;
                obj.fixOutStart = time;
                assert(~isnan(obj.fixInStart))
                obj.trialFixS = obj.trialFixS + (obj.fixOutStart - obj.fixInStart);
                
                %fprintf('fix out @%0.3f\t\t\t', time-obj.fixationTrackStarted)
                %fprintf('accum. time in: %0.3f\n', obj.trialFixS);
            end
        end
    end    
end


