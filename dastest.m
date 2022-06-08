BtOn = 0;  %if using button presses set to 1
Par.Board = int32(22);  %mcc board = 22; Demo-board = 0
Par.nChannels = 8;
dasinit( Par.Board, Par.nChannels);  %mexfunction acces!!

dasbit(6,1);

dasclose(Par.Board);