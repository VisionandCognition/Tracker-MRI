global LPStat

LPStat = dasinit(int32(0),2);

N = 400;
Time = zeros(N,1);
Hit = zeros(N,1);
Xp = zeros(N,1);
Yp = zeros(N,1);

dasreset( 2 )

for n = 1:N
    
    if LPStat(2) ~= 2
        dasrun(2)
    else
        daspause(2)
    end
    Time(n) = LPStat(1);
    Hit(n) = LPStat(2);
    if Time(n) >= 550 && Hit(n) == 0
        %calllib(Par.Dll, 'DO_Bit', 3, 1);
        dasbit( 3, 1);
    end
    %dasgetaverage();
    %Xp(n) = LPStat(7); %average position over window initialized in DasInit
    %Yp(n) = LPStat(8);
end

%calllib(Par.Dll, 'DO_Bit', 3, 0);
dasbit( 3, 0);
D = dasgettrace();
Time(n+1) = LPStat(1);
%D = reshape(trace, 1024, 2);
 
as = (1:length(D))+ Time(n+1) - 1024;
plot(as, D(:,[1 2]))

S = LPStat(5);
hold on, line([S S], [0 1000], 'color', 'r')

%hold on, plot(Hit)

%%
global LPStat

WIN = [   0,  0, 200, 200, 0; ...
           2000, 0, 500, 500, 2; ...
           -300, -300, 100, 100, 1].';
NumWins = size(WIN, 2);

%calllib(Par.Dll, 'Set_Window', NumWins, WIN(:), 0)       
dassetwindow( NumWins, WIN(:), 0, 1, 1 ) 
daszero();
 