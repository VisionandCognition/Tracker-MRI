function [Hit Time] = DasCheck

        global Par

        persistent PC %cached previous eye position
        persistent LObj %cached handel to plot object
        
%        persistent SObj %cached handel to plot object
%        persistent Tick %every tick update noise plot

        Hit = LPStat(1);   %Hit yes or no           
        Time = LPStat(0);  %time
        
       
        POS = dasgetposition();                
        P = POS.*Par.ZOOM; %average position over window initialized in DasIni
        
%    If you start using matlab R2014b and above use following lines instead of next      
%         if  ishandle(LObj)
%             addpoints(LObj,[PC(1) P(1)],[PC(2) P(2)]);
%         else
%             LObj = animatedline( [P(1) P(1)],  [P(2) P(2)], 'MaximumNumPoints',200);
%         end

        if  ishandle(LObj)
            set(LObj,  'XData', [PC(1) P(1)],  'YData', [PC(2) P(2)])
        else
            LObj = line( 'XData', [P(1) P(1)],  'YData', [P(2) P(2)], 'EraseMode','none');
        end
        

        
               
%         if isempty(Tick) || Tick > Time
%              Tick = Time;
%         end
%                 if  Time - Tick > 200 && Par.NoiseUpdate %update every 200 ms
%                     P = dasgetnoise();
%                     %2* standard error of noise in x & y direction                    
%                     SDx = ([-P(1) 0 P(1) 0 -P(1)] + Par.OFFx)* Par.ZOOM;
%                     SDy = ([0 P(2) 0 -P(2) 0]+ Par.OFFy)* Par.ZOOM;                  
%                     if  isempty(SObj) || ~ishandle(SObj)
%                         SObj = line( 'XData', SDx,  'YData', SDy, 'color', 'g', 'EraseMode','none');
% 
%                     else
%                         set(SObj, 'XData', SDx,  'YData', SDy)
% 
%                     end
%                     Tick = Time;
%                 end

            drawnow %update screen
            %cache the following values
            PC = P;
            


        