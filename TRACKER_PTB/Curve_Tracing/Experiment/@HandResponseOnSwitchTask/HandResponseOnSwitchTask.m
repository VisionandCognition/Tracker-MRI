classdef HandResponseOnSwitchTask < handle
    %HANDRESPONSEONSWITCHTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        goBarOrient =  1; % 1=default, 2=switched
        
        curr_response = 'none'; % response of current trial (correct, false ...)
        curr_hand = 0; % hand that gave response of current trial
        
        responses_hand = struct(...
            'correct', [0 0], ... L, R
            'false', [0 0], ...
            'miss', [0 0], ...
            'early', [0 0], ...
            'break_fix', [0 0]);
        responses_curr = struct(...
            'correct', [0], ...
            'false', [0], ...
            'miss', [0], ...
            'early', [0], ...
            'break_fix', [0]);
        responses_loc = struct(...
            'correct', [0 0 0 0 0], ... UpL DownL UpR DownR Center
            'false', [0 0 0 0 0], ...
            'miss', [0 0 0 0 0], ...
            'early', [0 0 0 0 0], ...
            'break_fix', [0 0 0 0 0]);
        
    end
    
    methods
        function obj = HandResponseOnSwitchTask()
        end
        
        checkResponses_PreFixation(obj, lft);
        checkResponses_PreSwitch(obj, lft);
        checkResponses_Switched(obj, lft);
        checkResponses_PostSwitch(obj, lft);
    end
    methods(Abstract, Access = protected)
        startTrackingFixationTime(obj, time, fixIn);
        stopTrackingFixationTime(obj, time);
    end
    methods(Abstract)
        updateState(obj, state, time);
    end
    
end

