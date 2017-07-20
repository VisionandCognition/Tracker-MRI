classdef CTShapedCheckerboard < FullscreenCheckerboard
    %CTSHAPEDCHECKERBOARD The fullscreen checkerboard masked to just the
    % areas of the Curve Tracing Stimuli.
    
    properties
        curves = nan;
        %maskedCB = nan; % checkboard with masks applied
        maskedCBTexture = nan; % all the checkerboard patterns
        
        % The stimuli_params are used by the Fullscreen Checkerboard
        % for the center target. The following are for the stimuli outside
        % of the center target. They have "curve" in the name, because the
        % stimuli outside of the target contain curves, although it also
        % includes the target shapes.
        curve_stimuli_params; % parameters for each individual stimulus
        curveStimuliParamsPath = NaN;
        curr_curve_stim = NaN; % parameters for the stimulus of the current trial
        curr_curve_stim_index = -1; % indexes curve_stimuli_params
    end
    
    methods
        function obj = CTShapedCheckerboard(commonParams, ...
                checkerboardParams, ...
                curveStimParams, ...
                taskName)
            if nargin < 4
                taskName = 'CT-Shaped Checkerboard';
            end
            obj = obj@FullscreenCheckerboard(commonParams, checkerboardParams, taskName);
            
            obj.curveStimuliParamsPath = which(curveStimParams);
            obj.curve_stimuli_params = readtable(obj.curveStimuliParamsPath);
        end
        
        function [val, status] = param(obj, var, varargin)
            try
                val = obj.curr_curve_stim(var);
                status = true;
            catch ME
                % Only catch errors due to the key not being found
                if ~strcmp(ME.identifier, 'MATLAB:Containers:Map:NoKey') && ...
                        ~strcmp(ME.identifier, 'MATLAB:badsubscript')
                    rethrow(ME);
                end
                
                % This will check for the parameters in curr_stim and then
                % taskParams.
                [val, status] = param@FullscreenCheckerboard(obj, var, varargin{:});
            end
            if nargout < 2 && ~status
                % if calling function doesn't get the status value and
                %   it is false, throw an error.
                error('Parameter variable %s does not exist!', var);
            end
        end
        
        lft = drawStimuli(obj, lft);
    end
    
    methods (Access = protected)
        update_PrepareStim(obj);
        [pts, pts_col] = calcCurve(obj, indpos);
    end
end