function cgplotstim( STM, OBJ )

    ID = [OBJ(:).Id ]; %ids
    
    len = length(STM);
    if len > 0
        for i = 1:len
            Ix = find(ID==STM(i));
            switch OBJ(Ix).Type
                case 'Bezier'
                    cgbezier(OBJ(Ix).Data, 'B'); %blit sprite of bezier
                    
                case 'Dot'
                    cgdot(OBJ(Ix).Data, 'P');
                
                case 'Box'
                    cgbox(OBJ(Ix).Data, 'P');
                    
                case 'Texture'
                    cgTexture(OBJ(Ix).Data, 'P', STM(i)); %this is a sprite 
                    
                case 'Bitmap'
                    cgbitmap(OBJ(Ix).Data, 'P');  %this is a sprite
                    
             %   case 'Sprite'
              %      cgdrawsprite(STM(i), 0, 0)
                    %cgflip
                    %just must make and draw onto this sprite yourself 
                    
                case 'Polyline'
                    cgPolyline(OBJ(Ix).Data, 'P');
                    
                case 'Randompattern'
                    if OBJ(Ix).Data.isLoaded
                        cgdrawsprite(OBJ(Ix).Id,0,0)
                    else
                        cgRandompattern( OBJ(Ix).Data, 'plot');
                        %displays but does not save the data
                    end
            end
        end
    end