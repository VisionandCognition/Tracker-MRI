 function [lft] = drawStimuli(obj, lft)
 global Par;
 
    % Background
    Screen('FillRect',Par.window,obj.param('BGColor').*Par.ScrWhite);

    obj.update();

    obj.drawFix();

    % Target bar - "Go bar"
    if ~obj.taskParams.GoBarOrientation(Par.CurrOrient) %horizontal
        rect=[...
            obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(1)/2, ...
            obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(2)/2, ...
            obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(1)/2, ...
            obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(2)/2];
    else
        rect=[...
            obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)-obj.taskParams.GoBarSizePix(2)/2, ... left
            obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)-obj.taskParams.GoBarSizePix(1)/2, ... top
            obj.taskParams.FixPositionsPix(Par.PosNr,1)+Par.ScrCenter(1)+obj.taskParams.GoBarSizePix(2)/2, ... right
            obj.taskParams.FixPositionsPix(Par.PosNr,2)+Par.ScrCenter(2)+obj.taskParams.GoBarSizePix(1)/2];
    end
    
    Screen('FillRect', Par.window, obj.taskParams.GoBarColor .* Par.ScrWhite, rect);
    
    % Draw on screen
    lft=Screen('Flip', Par.window,lft+.9*Par.fliptimeSec);
end
