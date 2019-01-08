function [stimulus, offscr] = ck_figgnd(Stm, screenNumber)
% ck_figgnd - create fig-gnd stimuli
% adapted for Tracker@NIN, C.Klink, Jan 2019

global Par
open_tex = []; % keep track of open textures and close them at the end

%% Draw texture in offscreen windows & make texture -----------------------
% create neutral background texture --
zoomfactor = 2.5;
[offscr.w, offscr.rect] = Screen('OpenOffscreenWindow', ...
    screenNumber, Stm.Gnd(1).backcol*Par.ScrWhite, ...
    zoomfactor*Par.wrect); %#ok<*SAGROW>
Screen('BlendFunction', offscr.w, ...
    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
[offscr.center(1), offscr.center(2)] = RectCenter(offscr.rect);

%% Create textured background ---------------------------------------------
fprintf('Creating Ground-texture seeds...\n');
ScrSize = Par.wrect(3:4);
for gs = 1:Stm.Gnd_all.NumSeeds
    switch Stm.StimType{2}
        case 'lines'
            % Create lines --------------------------------------------
            Surf_tot = ScrSize(1)*ScrSize(2);
            Surf_line = Stm.Gnd_all.lines.length*Stm.Gnd_all.lines.width;
            Stm.Gnd_all.lines.n = round(...
                Stm.Gnd_all.lines.density*(Surf_tot/Surf_line));
            X1 = round(rand(round(Stm.Gnd_all.lines.n*(zoomfactor^2)),1).*...
                (zoomfactor*ScrSize(1)+...
                (Stm.Gnd_all.lines.length*zoomfactor))-...
                (offscr.center(1)+Stm.Gnd_all.lines.length));
            Y1 = round(rand(round(Stm.Gnd_all.lines.n*(zoomfactor^2)),1).*...
                (zoomfactor*ScrSize(2)+...
                (Stm.Gnd_all.lines.length*zoomfactor))-...
                (offscr.center(2)+Stm.Gnd_all.lines.length));
            X2 = round(X1 + Stm.Gnd_all.lines.length);
            Y2 = Y1; XY = [];
            for i=1:size(X1,1)
                XY = [XY [X1(i) X2(i); Y1(i) Y2(i)]]; %#ok<*AGROW>
            end
            
            % draw lines in offscreen window
            Screen('FillRect',offscr.w,Stm.Gnd_all.backcol*Par.ScrWhite)
            Screen('DrawLines', offscr.w, XY, Stm.Gnd_all.lines.width,...
                Stm.Gnd_all.lines.color*Par.ScrWhite, offscr.center,1);
            temparray = Screen('GetImage',offscr.w);
            stimulus.Gnd_all.array{gs,1} = uint8(temparray);
            
            if Stm.InvertPolarity
                % draw lines in offscreen window
                Screen('FillRect',...
                    offscr.w,Stm.Gnd_all.lines.color*Par.ScrWhite)
                Screen('DrawLines', offscr.w, XY, Stm.Gnd_all.lines.width,...
                    Stm.Gnd_all.backcol*Par.ScrWhite, offscr.center,1);
                temparray = Screen('GetImage',offscr.w);
                stimulus.Gnd_all.array{gs,2} = uint8(temparray);
            end
            
            % make textures >> we need it here for figure generation but we
            % cannot save them so the runstim needs to regenerate them.
            Gnd_all.tex{gs,1} = Screen('MakeTexture',Par.window,...
                stimulus.Gnd_all.array{gs,1});
            open_tex = [open_tex Gnd_all.tex{gs,1}];
            if Stm.InvertPolarity
                Gnd_all.tex{gs,2} = Screen('MakeTexture',Par.window,...
                    stimulus.Gnd_all.array{gs,2});
                open_tex = [open_tex Gnd_all.tex{gs,2}];
            end
            
        case 'dots'
            % Create dots ---------------------------------------------
            Surf_tot = ScrSize(1)*ScrSize(2);
            Surf_dot = Stm.Gnd_all.dots.size^2;
            Stm.Gnd_all.dots.n = round(...
                Stm.Gnd_all.dots.density*(Surf_tot/Surf_dot));
            X1 = round(...
                rand(round(Stm.Gnd_all.dots.n*(zoomfactor^2)),1).*...
                (zoomfactor*ScrSize(1))-offscr.center(1));
            Y1 = round(...
                rand(round(Stm.Gnd_all.dots.n*(zoomfactor^2)),1).*...
                (zoomfactor*ScrSize(2))-offscr.center(2));
            XY = [X1'; Y1'];
            
            % draw dots in offscreen window
            if Stm.MoveStim.nFrames > 0
                for ms = 1:Stm.MoveStim.nFrames+1
                    Screen('FillRect',offscr.w,...
                        Stm.Gnd_all.backcol*Par.ScrWhite)
                    if ms>1
                        XY = [XY(1,:)+Stm.MoveStim.XY(1)*Par.PixPerDeg;...
                            XY(2,:)+Stm.MoveStim.XY(2)*Par.PixPerDeg];
                    end
                    Screen('DrawDots', offscr.w, XY, ...
                        Stm.Gnd_all.dots.size,...
                        Stm.Gnd_all.dots.color*Par.ScrWhite,...
                        offscr.center,Stm.Gnd_all.dots.type);
                    array = Screen('GetImage',offscr.w);
                    stimulus.Gnd_all.array{gs,ms,1} = uint8(array);
                    
                    Gnd_all.tex{gs,ms,1} = Screen('MakeTexture',Par.window,...
                        stimulus.Gnd_all.array{gs,ms,1});
                    open_tex = [open_tex Gnd_all.tex{gs,ms,1}];
                    
                    if Stm.InvertPolarity
                        Screen('FillRect',offscr.w,...
                            Stm.Gnd_all.dots.color*Par.ScrWhite)
                        Screen('DrawDots', offscr.w, XY, ...
                            Stm.Gnd_all.dots.size,...
                            Stm.Gnd_all.backcol*Par.ScrWhite,...
                            offscr.center,Stm.Gnd_all.dots.type);
                        array = Screen('GetImage',offscr.w);
                        stimulus.Gnd_all.array{gs,ms,2} = uint8(array);
                        
                        Gnd_all.tex{gs,ms,2} = Screen('MakeTexture',Par.window,...
                            stimulus.Gnd_all.array{gs,ms,2});
                        open_tex = [open_tex Gnd_all.tex{gs,ms,2}];
                    end
                end
            else
                Screen('FillRect',offscr.w,...
                    Stm.Gnd_all.backcol*Par.ScrWhite)
                Screen('DrawDots', offscr.w, XY, ...
                    Stm.Gnd_all.dots.size,...
                    Stm.Gnd_all.dots.color*Par.ScrWhite,...
                    offscr.center,Stm.Gnd(g).dots.type);
                array = Screen('GetImage',offscr.w);
                stimulus.Gnd_all.array{gs,1,1} = uint8(array);
                
                if Stm.InvertPolarity
                    Screen('FillRect',offscr.w,...
                        Stm.Gnd_all.dots.color*Par.ScrWhite)
                    Screen('DrawDots', offscr.w, XY, ...
                        Stm.Gnd_all.dots.size,...
                        Stm.Gnd_all.backcol*Par.ScrWhite,...
                        offscr.center,Stm.Gnd_all.dots.type);
                    array = Screen('GetImage',offscr.w);
                    stimulus.Gnd(g).array{gs,1,1} = uint8(array);
                end
                
            end
            
            Gnd_all.tex{gs,1} = Screen('MakeTexture',Par.window,...
                stimulus.Gnd_all.array{gs,1});
            open_tex = [open_tex Gnd_all.tex{gs,1}];
            if Stm.InvertPolarity
                Gnd_all.tex{gs,2} = Screen('MakeTexture',Par.window,...
                    stimulus.Gnd_all.array{gs,2});
                open_tex = [open_tex Gnd_all.tex{gs,2}];
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
    stimulus.Fig(f).RectDest = round([Stm.FigCenter(1)-FigSize(1)/2 ...
        Stm.FigCenter(2)-FigSize(2)/2 ...
        Stm.FigCenter(1)+FigSize(1)/2 ...
        Stm.FigCenter(2)+FigSize(2)/2 ]);
    stimulus.Fig(f).RectSrc = round([offscr.center(1)-FigSize(1)/2 ...
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
    stimulus.Fig(f).ori_ind = Stm.Fig(f).ori_ind;
    
    switch Stm.StimType{2}
        case 'lines'
            Screen('FillRect',offscr.w,0)
            if strcmp(Stm.Fig(f).shape,'Triangle_up') || ...
                    strcmp(Stm.Fig(f).shape,'Triangle_down')
                Screen('FillPoly',offscr.w,[],Stm.Fig(f).Triangle,1)
            elseif strcmp(Stm.Fig(f).shape,'Oval')
                Screen('FillOval',offscr.w,[],stimulus.Fig(f).RectSrc)
            elseif strcmp(Stm.Fig(f).shape,'Rectangle')
                Screen('FillRect',offscr.w,[],stimulus.Fig(f).RectSrc,1)
            end
            temparray = Screen('GetImage',offscr.w);
            stimulus.Fig(f).figmask = uint8(temparray(:,:,1));
            
        case 'dots'
            Screen('FillRect',offscr.w,0)
            if strcmp(Stm.Fig(f).shape,'Triangle_up') || ...
                    strcmp(Stm.Fig(f).shape,'Triangle_down')
                Screen('FillPoly',offscr.w,[],Stm.Fig(f).Triangle,1)
            elseif strcmp(Stm.Fig(f).shape,'Oval')
                Screen('FillOval',offscr.w,[],stimulus.Fig(f).RectSrc)
            elseif strcmp(Stm.Fig(f).shape,'Rectangle')
                Screen('FillRect',offscr.w,[],stimulus.Fig(f).RectSrc,1)
            end
            temparray = Screen('GetImage',offscr.w);
            stimulus.Fig(f).figmask = uint8(temparray(:,:,1));
    end
end

switch Stm.StimType{2}
    case 'lines'
        for ori = 1:length(Stm.Fig_all.orientations)
            for fs=1:Stm.Gnd_all.NumSeeds
                for p = 1:size(Gnd_all.tex,2)
                    Screen('FillRect',offscr.w,0)
                    Screen('DrawTexture',offscr.w,...
                        Gnd_all.tex{fs,p},[],[],Stm.Fig_all.orientations(ori));
                    array = Screen('GetImage',offscr.w);
                    stimulus.Fig_all.array{fs,p,ori} = uint8(array);
                end
            end
        end
    case 'dots'
        % do nothing
end

%% Close the created textures
Screen('Close',open_tex);
