clc;
%dasinit(22,6)
keyIsDown = false;
tSet = false;
SecondsRunning = 0;
hhh=figure;
pause(1);
tic;
while ishandle(hhh) %~keyIsDown
    dasrun(5);
    %[Hit Time] = DasCheck;
    Hit = LPStat(1);   %Hit yes or no           
    Time = LPStat(0);  %time
    P = dasgetposition();
    ChanLevels=dasgetlevel;
    
%     if ~tSet
%         t0=Time;
%         tSet=true;
%     end
%     if Time-t0 > SecondsRunning*1000
    if toc > SecondsRunning
        fprintf(['Running correctly for ' num2str(SecondsRunning) 's\n']);
        SecondsRunning = SecondsRunning +1;
        dasreset(0);
        SetWindowDas;
    end
    %[keyIsDown,secs,keycode] = KbCheck;
end
%dasclose();