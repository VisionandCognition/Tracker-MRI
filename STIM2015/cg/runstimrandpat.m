function runstim(Hnd)
 %Updated 26_03_2013 Chris van der Togt

 global Par   %global parameters
 global LPStat  %das status values, acronym for Data Aquisition System
 global StimObj %stimulus objects
 
 if ~isfield(StimObj, 'Stm')
     disp('ERROR: No stimulus');
     return
 end
 
 Times = Par.Times; %copy timing structure
 BG = Par.BG; %background Color
 cgflip(BG(1), BG(2), BG(3))
 
 Stms = StimObj.Stm;   %all stimuli
 Objs = StimObj.Obj;   %all graphical objects
 IDs = [ Objs(:).Id ]; %Ids of all graphical objects
 
 %they should all be not loaded, but just to make sure
  for i = 1:length(IDs) 
      if strcmp(Objs(i).Type, 'Texture') || strcmp(Objs(i).Type, 'Bitmap') || strcmp(Objs(i).Type, 'Bezier') || strcmp(Objs(i).Type, 'Randompattern')
           Objs(i).Data.isLoaded = false;
      end
  end
 
 %....EPOCHS /EVENTS...; represent subsequent stages during a trial
 FIX = 1;
 STM = 2;
 TARG = 3;
 TARGOF = 4;
 %MICR = 5;
FS = 0;
FO = 0;

%////YOUR STIMULATION CONTROL LOOP /////////////////////////////////
   Hit = 2;
   Par.ESC = false; %escape has not been pressed
   while ~Par.ESC   
       %Pretrial

%SETUP YOUR STIMULI FOR THIS TRIAL

    if Par.Drum && Hit ~= 2 %if drumming and this was an error trial
        %just redo with current sttings
    else
    %randomization
        I = ceil(rand*length(Stms));
        %or use custom randomisation procedure
        
        %condition and associated stimuli
        EVENT = Stms(I).Event;
        %calllib(Par.Dll, 'DO_Word', I); %send word bit and condition
        dasword( I); %send word bit and condition
        
    %timing
        PREFIXT = Times.ToFix; %time to enter fixation window
        FIXT = fix(Times.Fix + rand*Times.RndFix); %time to fix before stim onset
        STIMT = fix(Par.Times.Stim + rand*Times.RndStim); %time that stimulus is displayed
        TARGT = fix(Times.Targ + round(2*rand-1)*Times.RndTarg); %time to fix before target onset
        RACT = Times.Rt;      %reaction time
        
        FLtime = Par.fliptime;  %adjusting for fliptime       
        STIMT = (round(STIMT/FLtime) - 0) * FLtime;
        TARGT = (round(TARGT/FLtime) - 0) * FLtime;
                
    %control window setup    
        FI = find(IDs == Stms(I).Fix, 1);
        TI = find(IDs == Stms(I).Targ, 1);
        WIN = [ Objs(FI).Data.cx,  Objs(FI).Data.cy, Par.PixPerDeg*Par.FixWdDeg, Par.PixPerDeg*Par.FixHtDeg, 0; ... %Fix
                Objs(TI).Data.cx,  Objs(TI).Data.cy, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, 2 ];   %Targ
        Par.OFFx = Objs(FI).Data.cx;
        Par.OFFy = Objs(FI).Data.cy;

        Alt = Stms(I).Talt{:};
        for k = 1:length(Alt)
            AI = find(IDs == Alt(k), 1);
            WIN = [ WIN; ...
                    Objs(AI).Data.cx,  Objs(AI).Data.cy, Par.PixPerDeg*Par.TargWdDeg, Par.PixPerDeg*Par.TargHtDeg, 1 ]; %TAlt
        end
        Par.WIN = WIN';

%%%%%%%preload tectures and bitmaps, Beziers and Randompatterns as sprites,
%%%%%%%and free video memory of obsolete sprites

         Ids = unique([EVENT{:}]); %get all object ids in stimulus 
         Notused = setxor(IDs, Ids);
        %free memory of obsolete sprites
        for id = Notused %indices into notused objects
            idx = find(IDs == id); %obtain index to the object corresponding with this id
            if strcmp(Objs(idx).Type, 'Texture') || strcmp(Objs(idx).Type, 'Bitmap') || strcmp(Objs(idx).Type, 'Bezier') || strcmp(Objs(idx).Type, 'Randompattern')
                if Objs(idx).Data.isLoaded
                    cgfreesprite(id) %unload this sprite to make memory free
                    Objs(idx).Data.isLoaded = false;
                end
            end
        end
        %load new sprites
        for id = Ids
           idx = find(IDs == id);
           if strcmp(Objs(idx).Type, 'Texture') 
               OBJ = Objs(idx).Data;
               if ~(OBJ.isLoaded) %is not loaded
                    Objs(idx).Data = cgTexture(OBJ, 'L', id); %(L)oad the texture
               end
           elseif strcmp(Objs(idx).Type, 'Bitmap')
               OBJ = Objs(idx).Data;
               if ~(OBJ.isLoaded) %is not loaded
                    Objs(idx).Data = cgBitmap(OBJ, 'L', id); %Load the bitmap
               end
           elseif strcmp(Objs(idx).Type, 'Bezier')
               OBJ = Objs(idx).Data;
               if ~(OBJ.isLoaded) %is not loaded
                    Objs(idx).Data = cgBezier(OBJ, 'S', id); %draw the bezier on a sprite
               end
           elseif strcmp(Objs(idx).Type, 'Randompattern')    
               OBJ = Objs(idx).Data;
               %should be reloaded on each trial
               %if ~(OBJ.isLoaded) %is not loaded
                    Objs(idx).Data = cgRandompattern(OBJ, 'sprite', id); %draw the Randompattern on a sprite
                    BM = Objs(idx).Data.BM;
               %end
           end
        end
    end
    
%///////////////////////////////////////////////////////////////////// 
%START THE TRIAL
    %set control window positions and dimensions
    refreshtracker(1) %for your control display
    SetWindowDas      %for the dascard, initializes eye control windows
    Abort = false;    %whether subject has aborted before end of trial

%///////// EVENT 0 START FIXATING //////////////////////////////////////
    
    %cgellipse(Px,Py,20,20,[1 0 0 ],'f') %the red fixation dot on the screen
    cgplotstim(EVENT{FIX}, Objs);
    cgflip(BG(1), BG(2), BG(3))

     dasreset( 0 )  %test enter fix window
    %     0 enter fix window
    %     1 leave fix window
    %     2 enter target window
    

    %LPStat(1) = time (ms) passed since last reset
    %LPStat(2) = control window hit (1 : in or out, 2 : in correct
    %                  target window
    %LPStat.(3) = hit position x
    %LPStat(4) = hit postion y
    %LPStat(5) = reaction time
    %LPStat(6) = time saccade length

    
     %subject has to start fixating central dot
    Par.SetZero = false; %set key to false to remove previous presses
    %Par.Updatxy = 1; %centering key is enabled
    Time = 1;
    Hit = 0;
    while Time < PREFIXT && Hit == 0 
        pause(0.05)
                
       [Hit Time] = DasCheck; %retrieve position values and plot on Control display
    end 
 
%///////// EVENT 1 KEEP FIXATING or REDO  ////////////////////////////////////
        
    if Hit ~= 0  %subjects eyes are in fixation window keep fixating for FIX time
        %the tril bit has now automatically been set high!! If the monkey
        %loses fixation he gets another chance but the tril bit just stays
        %high and this results in a longer prestim period
        dasreset( 1 );  %set test parameters for exiting fix window
        
        Time = 1;
        Hit = 0;
        while Time < FIXT && Hit== 0
            %Check for 10 ms
            pause(0.005)
            
              %detect eye enter/exit of control windows
                                            %this will also automaitcally
                                            %occur during pauzes due to a
                                            %callback routine run every single ms
            [Hit Time] = DasCheck; %retrieve eyechannel buffer and events, plot eye motion, 
        end
        
        
        if Hit ~= 0 %eye has left fixation to early
                %possibly due to eye overshoot, give subject another chance
                dasreset( 0 );
                Time = 1;
                Hit = 0;
                while Time < PREFIXT && Hit == 0 
                    pause(0.005)
                    [Hit Time] = DasCheck; %retrieve position values and plot on Control display
                end 
             if Hit ~= 0  %subjects eyes are in fixation window keep fixating for FIX time  
                dasreset( 1 );  %test for exiting fix window
                
                Time = 1;
                Hit = 0;
                while Time < FIXT && Hit == 0
                    %Check for 10 ms
                    pause(0.005)                  
                    [Hit Time] = DasCheck;
                end
             else
                  Hit = -1; %the subject did not fixate
             end
        end
        
    else
        Hit = -1; %the subject did not fixate
    end
    
%///////// EVENT 2 DISPLAY STIMULUS //////////////////////////////////////
     if Hit == 0 %subject kept fixation, display stimulus
        Par.Trlcount = Par.Trlcount + 1;  %counts total number of trials for this session  
        
%change your display between these lines.......................
%             cgpencol(1,1,1)
%             cgrect(-462, 334, 100, 100) %test stimulus for light diode
%             cgellipse(Px,Py,20,20,[1 0 0 ],'f') %fixation dot
%             cgellipse(Par.WIN(1,2), Par.WIN(2,2), 20, 20, [1 0 0 ], 'f') %target
        cgplotstim(EVENT{STM}, Objs);
 %.............................................................. 
        FO = cgflip(BG(1), BG(2), BG(3));
        FS = FO;
        %cgflip('v'); %this is not nice; cgflip does not give good timing
        tic  %measure onset too 
        dasbit( Par.StimB, 1);   %send stimulus bit to TDT   
        dasreset( 1 );  %test for exiting fix window
        refreshtracker(2)  %set target window to green
        Time = 0;
        
 %prepare display for next flip TARGON.................
        if ~isempty(EVENT{TARG})
                cgplotstim(EVENT{TARG}, Objs);
                EPoch = min( STIMT-10, TARGT-50); %determine smallest time
                while Time < EPoch  && Hit == 0 
                     dasrun( 5 );
                    %get hit time 
                    [Hit Time] = DasCheck;   
                end
                FS = cgflip(BG(1), BG(2), BG(3));
                
        end
        if ~isempty(EVENT{TARGOF})
                    cgplotstim(EVENT{TARGOF}, Objs);                             
               %prepare display for next flip.................      
        end      
        
        while Time < TARGT-50  && Hit == 0  %Keep fixating till just before (50ms) target onset
                dasrun( 5 );
                %get hit time and plot eyemotion
                [Hit Time] = DasCheck; %plot eye motion in tracker
        end

            %how much time(ms) do we have left till target onset???  +
            %FlOP* FLtime
            delay = floor(TARGT - toc*1000 - FLtime/2); %hold up calling the next flip
            if delay > 0
                %calllib(Par.Dll, 'Check', delay)
                dasrun(delay)
                Hit = LPStat(2);  %don't wast time!!!! on updating the screen
            else
                disp('WARNING....not enough time between stimoffset and target onset.')
            end
            
%///////// EVENT 3 TARGET ONSET, REACTION TIME%%//////////////////////////////////////  

        if Hit == 0 %subject kept fixation, subject may make an eye movement
            FS = cgflip(BG(1), BG(2), BG(3)); 
        %    cgflip('v');    %this is not nice; cgflip doesnot give good timing
            dasbit( Par.TargetB, 1); %send target bit to TDT 
            dasreset(2);            %reset counter and check for entering target window
            %toc      %display this to check your internal timing
            refreshtracker(3) %set fix point to green

            Time = 0;
            while Time < RACT && Hit <= 0  %RACT = time to respond (reaction time)
                %Check for 5 ms
                dasrun( 5)
                [Hit Time] = DasCheck;
            end
            
        else
            Abort = true;
        end
        %END EVENT 3           
    else
        Abort = true;
    end
    %END EVENT 2
    cgflip(BG(1), BG(2), BG(3));

  %///////// POSTTRIAL AND REWARD ////////////////////////////////////// 
        if Hit ~= 0 && ~Abort %has entered a target window (false or correct)
        
            if Par.Mouserun
                HP = line('XData', Par.ZOOM * (LPStat(3) + Par.MOff(1)), 'YData', Par.ZOOM * (LPStat(4) + Par.MOff(2)), 'EraseMode','none');
            else
               HP = line('XData', Par.ZOOM * LPStat(3), 'YData', Par.ZOOM * LPStat(4), 'EraseMode','none');
            end
            set(HP, 'Marker', '+', 'MarkerSize', 20, 'MarkerEdgeColor', 'm')
            %drawnow
                  
            if Hit == 2 && Par.Reward && LPStat(6) < Times.Sacc %correct target, give juice 
                                
                    dasbit( Par.CorrectB, 1);
                    dasbit( Par.RewardB, 1);
                    if BM == 1 
                        Rewardtime = Par.RewardTime;
                    else
                        Rewardtime = Par.RewardTime * 4;
                    end
                    
                    dasjuice( 5 ); 
                    Par.Corrcount = Par.Corrcount + 1; %log correct trials
                   % beep
 
                    pause(Rewardtime) %RewardTime is in seconds

                    dasbit( Par.RewardB, 0);
                    dasjuice( 0 ); 
                    
            
            elseif Hit == 1
                    dasbit(  Par.ErrorB, 1);
                    Par.Errcount = Par.Errcount + 1;
                   %in wrong target window
            end
            
            %keep following eye motion to plot complete saccade
            for i = 1:10   %keep targoff for 50ms
                pause(0.005) %not time critical, add some time to follow eyes
            %calllib(Par.Dll, 'Check', 5);
            DasCheck; %keep following eye motion
            end
            %Save_eyetrace( I )

        end

         if Hit ~= 2  %error response
              %add pause when subject makes error
             for i = 1:round(Times.Err/5)   %keep targoff for Times.Err(ms)
                 pause(0.005)
                % calllib(Par.Dll, 'Check', 5);
                DasCheck; 
             end
            
         end                       
         [ Hit Lasttime] = DasCheck;
%///////////////////////INTERTRIAL AND CLEANUP   
         display(['hit ' num2str(Hit) ' reactiontime: ' num2str(LPStat(5))  ' saccadetime: ' num2str(LPStat(6))]);
         disp(['stimulus-target duration: ' num2str((FS - FO)*1000) ' ms ']);  %check timing of target onset 

         %reset all bits to null
         for i = [0 1 2 3 4 5 6 7]  %Error, Stim, Saccade, Trial, Correct,  
             %calllib(Par.Dll, 'DO_Bit', i, 0);
             dasbit( i, 0); %clear bits
         end
         %calllib(Par.Dll, 'Clear_Word');
         dasclearword();
              
            SCNT = {'TRIALS'};
            SCNT(2) = { ['N: ' num2str(Par.Trlcount) ]};
            SCNT(3) = { ['C: ' num2str(Par.Corrcount) ] };
            SCNT(4) = { ['E: ' num2str(Par.Errcount) ] };
            set(Hnd(1), 'String', SCNT ) %display updated numbers in GUI
            
            SD = dasgetnoise(); 
            SD = SD./Par.PixPerDeg;
            
            set(Hnd(2), 'String', SD )

         cgpencol(BG(1), BG(2), BG(3)) %clear background before flipping
         cgrect
         cgflip(BG(1), BG(2), BG(3))         
         %pause( Times.InterTrial/1000 ) %pause is called with seconds
                                       %Times.InterTrial is in ms
         Time = Lasttime;                              
         while Time < Times.InterTrial + Lasttime
             pause(0.005)
             %calllib(Par.Dll, 'Check', 5);
            [Hit Time] = DasCheck;
         end
        
   end   %WHILE_NOT_ESCAPED%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

 

     