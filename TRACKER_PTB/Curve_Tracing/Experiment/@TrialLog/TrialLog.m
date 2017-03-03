classdef TrialLog < handle
    %Log for each trial
    
    properties %(Access = private)
        stim_entries = table;
    end
    
    methods
        function obj = TrialLog()
        end
        function recordTrialStimulus(obj, stimInfo)
            vals = stimInfo.values;
            keys = stimInfo.keys;
            
            msk = cellfun(@length, stimInfo.values)==1 | cellfun(@ischar, stimInfo.values);
            mkeys = ['StartTrial', 'EndTrial' keys(msk)];
            mvals = [nan nan vals(msk)];
            
            T2 = cell2table(mvals);
            T2.Properties.VariableNames = mkeys;
            
            obj.stim_entries = vertcat(obj.stim_entries, T2);
        end
        
        function record(obj, var, val)
            obj.(var) = val; % not tested
        end
        
        function write_csv(obj, filename)
            % to be written ...
            writetable(obj.stim_entries, filename);
        end
    end
    
end

