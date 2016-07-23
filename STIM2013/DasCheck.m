function [Hit Time] = DasCheck

        global Par
        global LPStat
        persistent PC %cached previous eye position
        persistent LObj %cached handel to plot object
        
%        persistent SObj %cached handel to plot object
%        persistent Tick %every tick update noise plot

        Hit = LPStat(2);   %Hit yes or no           
        Time = LPStat(1);  %time
        
       
        POS = dasgetposition();
                
        P = POS.*Par.ZOOM; %average position over window initialized in DasIni
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
            


        