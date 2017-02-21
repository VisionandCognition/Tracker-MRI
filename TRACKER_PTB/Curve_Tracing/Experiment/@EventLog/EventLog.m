classdef EventLog < handle
    %EVENTLOG Creates a list of events
    %   Detailed explanation goes here
    
    properties( Access = private)
        log = [];
        queue = [];
        saveNextFlipTime = false;
    end
    
    methods
        function add_entry(obj, time, event, info )
            nEvents = length(obj.log)+1;
            obj.log(nEvents).time = time;
            obj.log(nEvents).type = event;
            if nargin >= 4
                obj.log(nEvents).info = info;
            end
        end
        function queue_entry(obj, event, info )
            nEvents = length(obj.queue)+1;
            obj.queue(nEvents).type = event;
            if nargin >= 3
                obj.queue(nEvents).info = info;
            end
        end
        function save_next_flip(obj)
            obj.saveNextFlipTime = true;
        end
        function screen_flip(obj, time)
            obj.timestamp_queue(time);
            if obj.saveNextFlipTime
                obj.add_entry(obj, time, 'ScreenUpdate');
                obj.saveNextFlipTime = false;
            end
        end
        function log = getEntries(obj)
            log = obj.log;
        end
        function write_csv(obj, filename)
            fid = fopen(filename, 'w');
            fprintf(fid,'time,event,info\n');
            for e = 1:length(obj.log)
                fprintf(fid,'%f,"%s","%s"\n', ...
                    obj.log(e).time, obj.log(e).type, obj.log(e).info);
            end
            fclose(fid);
        end
    end
    methods(Access = protected)
        function timestamp_queue(obj, time)
            for e = 1:length(obj.queue)
                obj.add_entry(time, obj.queue(e).type, obj.queue(e).info)
            end
            obj.queue = [];
        end
    end
    
end

