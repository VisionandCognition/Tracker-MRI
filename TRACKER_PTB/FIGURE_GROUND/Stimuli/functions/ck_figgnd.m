function [stimulus, offscr] = ck_figgnd(Stm)
% ck_figgnd - create fig-gnd stimuli
% adapted for Tracker@NIN, C.Klink, Jan 2019

global Par
open_tex = []; % keep track of open textures and close them at the end

%% Draw texture in offscreen windows & make texture -----------------------
% create neutral background texture --
zoomfactor = 2;
[offscr.w, offscr.rect] = Screen('OpenOffscreenWindow', ...
    screenNumber, Stm.Gnd(1).backcol*Par.ScrWhite, ...
    zoomfactor*Par.wrect); %#ok<*SAGROW>
Screen('BlendFunction', offscr.w, ...
    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
[offscr.center(1), offscr.center(2)] = RectCenter(offscr.rect);

%% Create textured background ---------------------------------------------
fprintf('Creating Ground-texture seeds...\n');
ScrSize = Par.wrect(3:4);
for g = 1:length(Stm.Gnd)
    for gs = 1:Stm.Gnd(g).NumSeeds
        switch Stm.StimType{2}
            case 'lines'
                % Create lines --------------------------------------------
                Surf_tot = ScrSize(1)*ScrSize(2);
                Surf_line = Stm.Gnd(g).lines.length*Stm.Gnd(g).lines.width;
                Stm.Gnd(g).lines.n = round(...
                    Stm.Gnd(g).lines.density*(Surf_tot/Surf_line));
                X1 = round(rand(Stm.Gnd(g).lines.n*(zoomfactor^2),1).*...
                    (zoomfactor*ScrSize(1)+...
                    (Stm.Gnd(g).lines.length*zoomfactor))-...
                    (offscr.center(1)+Stm.Gnd(g).lines.length));
                Y1 = round(rand(Stm.Gnd(g).lines.n*(zoomfactor^2),1).*...
                    (zoomfactor*ScrSize(2)+...
                    (Stm.Gnd(g).lines.length*zoomfactor))-...
                    (offscr.center(2)+Stm.Gnd(g).lines.length));
                X2 = round(X1 + Stm.Gnd(g).lines.length);
                Y2 = Y1; XY = [];
                for i=1:size(X1,1)
                    XY = [XY [X1(i) X2(i); Y1(i) Y2(i)]]; %#ok<*AGROW>
                end
                
                % draw lines in offscreen window
                Screen('FillRect',offscr.w,Stm.Gnd(g).backcol*Par.ScrWhite)
                Screen('DrawLines', offscr.w, XY, Stm.Gnd(g).lines.width,...
                    Stm.Gnd(g).lines.color*Par.ScrWhite, offscr.center,1);
                stimulus.Gnd(g).array{gs,1} = Screen('GetImage',offscr.w);
                
                if Stm.InvertPolarity
                    % draw lines in offscreen window
                    Screen('FillRect',...
                        offscr.w,Stm.Gnd(g).lines.color*Par.ScrWhite)
                    Screen('DrawLines', offscr.w, XY, Stm.Gnd(g).lines.width,...
                        Stm.Gnd(g).backcol*Par.ScrWhite, offscr.center,1);
                    stimulus.Gnd(g).array{gs,2} = Screen('GetImage',offscr.w);
                end
            case 'dots'
                % Create dots ---------------------------------------------
                Surf_tot = ScrSize(1)*ScrSize(2);
                Surf_dot = Stm.Gnd(g).dots.size^2;
                Stm.Gnd(g).dots.n = round(...
                    Stm.Gnd(g).dots.density*(Surf_tot/Surf_dot));
                X1 = round(...
                    rand(Stm.Gnd(g).dots.n*(zoomfactor^2),1).*...
                    (zoomfactor*ScrSize(1))-offscr.center(1));
                Y1 = round(...
                    rand(Stm.Gnd(g).dots.n*(zoomfactor^2),1).*...
                    (zoomfactor*ScrSize(2))-offscr.center(2));
                XY = [X1'; Y1'];
            
                % draw dots in offscreen window
                if Stm.MoveGnd.nFrames > 0
                    for ms = 1:Stm.MoveGnd.nFrames+1
                        Screen('FillRect',offscr.w,...
                            Stm.Gnd(g).backcol*Par.ScrWhite)
                        if ms>1
                            XY = [XY(1,:)+Stm.MoveGnd.XY(1);...
                                XY(2,:)+Stm.MoveGnd.XY(2)];
                        end
                        Screen('DrawDots', offscr.w, XY, ...
                            Stm.Gnd(g).dots.size,...
                            Stm.Gnd(g).dots.color*Par.ScrWhite,...
                            offscr.center,Stm.Gnd(g).dots.type);
                        stimulus.Gnd(g).array{gs,ms,1} = ...
                            Screen('GetImage',offscr.w);
                    end
                else
                    Screen('FillRect',offscr.w,...
                        Stm.Gnd(g).backcol*Par.ScrWhite)
                    Screen('DrawDots', offscr.w, XY, ...
                        Stm.Gnd(g).dots.size,...
                        Stm.Gnd(g).dots.color*Par.ScrWhite,...
                        offscr.center,Stm.Gnd(g).dots.type);
                    stimulus.Gnd(g).array{gs,1,1} = ...
                        Screen('GetImage',offscr.w);
                end
        end
        
        % make textures >> we need it here for figure generation but we  
        % cannot save them so the runstim needs to regenerate them.
        Gnd(g).tex{gs,1} = Screen('MakeTexture',w,...
            stimulus.Gnd(g).array{gs,1});
        open_tex = [open_tex Gnd(g).tex{gs,1}];
        if Stm.InvertPolarity
            Gnd(g).tex{gs,2} = Screen('MakeTexture',w,...
                stimulus.Gnd(g).array{gs,2});
            open_tex = [open_tex Gnd(g).tex{gs,2}];
        end
    end
end

%% Create figure rects and textures ---------------------------------------
fprintf('Creating Figure-texture seeds...\n');
for f = 1:length(Stm.Fig)
    
    FigSize = round(Stm.Fig(f).size*Par.PixPerDeg);
    FigPos = round(Stm.Fig(f).position*Par.PixPerDeg);
    
    Stm.FigCenter = [Par.ScrCenter(1)+FigPos(1) ...
        Par.ScrCenter(2)+FigPos(2)];
    Stm.Fig(f).RectDest = round([Stm.FigCenter(1)-FigSize(1)/2 ...
        Stm.FigCenter(2)-FigSize(2)/2 ...
        Stm.FigCenter(1)+FigSize(1)/2 ...
        Stm.FigCenter(2)+FigSize(2)/2 ]);
    Stm.Fig(f).RectSrc = round([offscr.center(1)-FigSize(1)/2 ...
        offscr.center(2)-FigSize(2)/2 ...
        offscr.center(1)+FigSize(1)/2 ...
        offscr.center(2)+FigSize(2)/2 ]);
    
    if strcmp(Stm.Fig(f).shape,'Triangle_up')
        Stm.Fig(f).Triangle = round([...
            offscr.center(1) offscr.center(2)-sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1)+FigSize(1)/2 offscr.center(2)+sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1)-FigSize(1)/2 offscr.center(2)+sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1) offscr.center(2)-sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2]);
    elseif strcmp(Stm.Fig(f).shape,'Triangle_down')
        Stm.Fig(f).Triangle = round([...
            offscr.center(1)-FigSize(1)/2 offscr.center(2)-sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1)+FigSize(1)/2 offscr.center(2)-sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1) offscr.center(2)+sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2 ;...
            offscr.center(1)-FigSize(1)/2 offscr.center(2)-sqrt(FigSize(1)^2-(FigSize(1)/2)^2)/2]);
    end
    
    switch Stm.StimType{2}
        case 'lines'
            for fs=1:Stm.Gnd(1).NumSeeds
                for p = 1:size(Stm.Gnd(1).tex,2)
                    Screen('FillRect',offscr.w,0)
                    Screen('DrawTexture',offscr.w,...
                        Gnd(1).tex{fs,p},[],[],Stm.Fig(f).orient);
                    array = Screen('GetImage',offscr.w);
                    
                    if fs == 1
                        Screen('FillRect',offscr.w,0)
                        if strcmp(Stm.Fig(f).shape,'Triangle_up') || ...
                                strcmp(Stm.Fig(f).shape,'Triangle_down')
                            Screen('FillPoly',offscr.w,[],Stm.Fig(f).Triangle,1)
                        elseif strcmp(Stm.Fig(f).shape,'Oval')
                            Screen('FillOval',offscr.w,[],Stm.Fig(f).RectSrc)
                        elseif strcmp(Stm.Fig(f).shape,'Rectangle')
                            Screen('FillRect',offscr.w,[],Stm.Fig(f).RectSrc,1)
                        end
                        Stm.Fig(f).figmask = Screen('GetImage',offscr.w);
                    end
                    Stm.Fig(f).textfig{fs,p} = ...
                        cat(3, array, Stm.Fig(f).figmask(:,:,1));
                end
            end
        case 'dots'
            for fs=1:Stm.Gnd(1).NumSeeds
                ms_gnd = Stm.MoveStim.nFrames+1:-1:1;
                for ms = 1:Stm.MoveStim.nFrames+1
                    Screen('FillRect',offscr.w,0)
                    Screen('DrawTexture',offscr.w, Gnd(1).tex{fs,ms_gnd(ms),1});
                    Stm.Fig(f).array{fs,ms,1} = Screen('GetImage',offscr.w);
                    
                    if fs == 1 && ms == 1
                        Screen('FillRect',offscr.w,0)
                        if strcmp(Stm.Fig(f).shape,'Triangle_up') || ...
                                strcmp(Stm.Fig(f).shape,'Triangle_down')
                            Screen('FillPoly',offscr.w,[],Stm.Fig(f).Triangle,1)
                        elseif strcmp(Stm.Fig(f).shape,'Oval')
                            Screen('FillOval',offscr.w,[],Stm.Fig(f).RectSrc)
                        elseif strcmp(Stm.Fig(f).shape,'Rectangle')
                            Screen('FillRect',offscr.w,[],Stm.Fig(f).RectSrc,1)
                        end
                        Stm.Fig(f).figmask = Screen('GetImage',offscr.w);
                    end
                    
                    stimulus.Fig(f).textfig{fs,ms,1} = ...
                        cat(3, Stm.Fig(f).array{fs,ms,1}, ...
                        Stm.Fig(f).figmask(:,:,1));
                    
                    if Stm.InvertPolarity
                        Screen('FillRect',offscr.w,0)
                        Screen('DrawTexture',offscr.w, ...
                            Gnd(1).tex{fs,ms_gnd(ms),2});
                        stimulus.Fig(f).array{fs,ms,2} = ...
                            Screen('GetImage',offscr.w);
                        stimulus.Fig(f).textfig{fs,ms,2} = ...
                            cat(3, stimulus.Fig(f).array{fs,ms,2}, ...
                            Stm.Fig(f).figmask(:,:,1));
                    end
                end
            end
    end
end

%% Close the created textures
Screen('Close',open_tex);
