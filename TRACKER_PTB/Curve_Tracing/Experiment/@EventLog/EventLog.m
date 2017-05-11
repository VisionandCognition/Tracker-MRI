classdef EventLog < handle
    %EVENTLOG Creates a list of events
    %   Detailed explanation goes here
    
    properties( Access = private)
        log = [];
        queue = [];
        saveNextFlipTime = false;
        beginExpTime = 0;
    end
    
    methods
        function begin_experiment(obj, time, readableDatestr)
            obj.beginExpTime = time;
            if nargin <= 2
                readableDatestr = datestr(clock,30);
            end
            obj.add_entry(time, 'NA', 'BeginExperiment', readableDatestr);
        end
        function nEvents = nEvents(obj)
            nEvents = length(obj.log)+1;
        end
        function add_entry(obj, time, task, event, info)
            assert(isnumeric(time))
            nEvents = length(obj.log)+1;
            obj.log(nEvents).time = time;
            obj.log(nEvents).task = task;
            obj.log(nEvents).type = event;
            obj.log(nEvents).record_time = GetSecs;
            if nargin >= 5
                obj.log(nEvents).info = info;
            end
        end
        function queue_entry(obj, task, event, info )
            nEvents = length(obj.queue)+1;
            obj.queue(nEvents).task = task;
            obj.queue(nEvents).type = event;
            if nargin >= 4
                obj.queue(nEvents).info = info;
            end
        end
        function save_next_flip(obj)
            obj.saveNextFlipTime = true;
        end
        function screen_flip(obj, time, taskName)
            assert(isnumeric(time))
            obj.timestamp_queue(time);
            if obj.saveNextFlipTime
                obj.add_entry(time, taskName, 'ScreenUpdate');
                obj.saveNextFlipTime = false;
            end
        end
        function log = getEntries(obj)
            log = obj.log;
        end
        function write_csv(obj, filename)
            fid = fopen(filename, 'w');
            fprintf(fid,'time_s,task,event,info,record_time_s\n');
            for e = 1:length(obj.log)
                line = sprintf('%0.4f,"%s","%s","%s",%0.4f\n', ...
                    obj.log(e).time - obj.beginExpTime, ...
                    obj.log(e).task, ...
                    obj.log(e).type, ...
                    obj.log(e).info, ...
                    obj.log(e).record_time - obj.beginExpTime);
                fprintf(fid, line);
            end
            fclose(fid);
        end
    end
    methods(Access = protected)
        function timestamp_queue(obj, time)
            assert(isnumeric(time))
            for e = 1:length(obj.queue)
                obj.add_entry(time, obj.queue(e).task, obj.queue(e).type, obj.queue(e).info)
            end
            obj.queue = [];
        end
    end
    
end

