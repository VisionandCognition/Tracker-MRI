function GiveRewardManual
% give manual reward

global Par;
global Log;
global StimObj;

Stm = StimObj.Stm;

    Par.RewardTimeCurrent = Par.RewardTimeManual;
    % Give the reward
    StartReward=GetSecs;
    if strcmp(computer,'PCWIN64')
        dasjuice(10); % 64bit das card
    else
        dasjuice(5) %old card dasjuice(5)
    end

    % Play back a sound
    if Par.RewardSound
        RewT=0:1/Par.RewSndPar(1):Par.RewardTimeCurrent;
        RewY=Par.RewSndPar(3)*sin(2*pi*Par.RewSndPar(2)*RewT);
        sound(RewY,Par.RewSndPar(1));
    end
    %stop the reward
    StopReward=false;
    while ~StopReward
        if GetSecs >= StartReward+Par.RewardTimeCurrent
            dasjuice(0);
            StopReward = true;
            Log.TotalReward = Log.TotalReward+Par.RewardTimeCurrent;
        end
    end
    Par.LastRewardTime = StartReward;
    %Log.events.add_entry(StartReward, Stm(1).task.name, 'Reward', 'Manual');
    Log.events.add_entry(StartReward, Stm(1).task.name, 'ManualReward', num2str(Par.RewardTimeCurrent));
end