%% create bt object 
tic;
b=Bluetooth('DBSDuino', 1);
b.Terminator = 'CR';
tt=toc;
fprintf(['Creating BT device took ' num2str(tt) 's\n']);


%% open BT
tic;
fopen(b);
tt=toc; 
fprintf(['Opening BT device for writing took ' num2str(tt) 's\n']);
    
%% Send to BT
fprintf(b, 'n5000');
fscanf(b)
pause(0.175);
% seems like at the moment we need a delay between calls for it to work
% ~200 ms works
%
fprintf(b, 's');
fscanf(b)


%% close BT
fclose(b)

