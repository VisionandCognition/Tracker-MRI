%% create bt object =======================================================
tic; b=Bluetooth('DBSDuino', 1); tt=toc;
b.Terminator = 'CR'; % carriage return
fprintf(['Creating BT device took ' num2str(tt) 's\n']);

%% open BT ================================================================
tic; fopen(b); tt=toc; 
fprintf(['Opening BT device for writing took ' num2str(tt) 's\n']);
    
%% Send to BT =============================================================
s_idx = 1; % first log

ln = query(b,'p'); % query all current parameters
fprintf(['\n' ln(1:end-1) '\n']); % white line in cmd & first line

dbsduino.status(s_idx).msg={}; % init log

ln_idx = 1; % first line index
while b.BytesAvailable > 2 % keep scanning till all useful lines are there
        ln = fscanf(b);
        if size(ln, 2) > 3
            dbsduino.status(s_idx).msg{ln_idx,1} = ln(2:end-1);
            fprintf([dbsduino.status(s_idx).msg{ln_idx} '\n']); 
            ln_idx=ln_idx+1;
        end
       pause(0.050)  % this delay is necessary for DBSduino to catch up
end
fprintf('\n');
pause(0.050) % wait a bit to let DBSduino catch up
flushinput(b) % empty buffer

%% Some more tests ========================================================
s_idx = 2; 

ln = query(b, 'n5000'); pause(0.050); % change num repetitions

Get_All_Parameters = false; % either get all parameter or only the changed

if Get_All_Parameters % get all parameters
    flushinput(b) % delete buffer
    ln = query(b,'p'); % query all current parameters
    pause(0.050);
    max_lines = 10;
    fprintf(['\n' ln(1:end-1) '\n']); % white line in cmd & first line
else
    max_lines = 1;
    fprintf(['-- Set parameter --\n' ln(1:end-1) '\n']); % white line in cmd & first line
end

dbsduino.status(s_idx).msg={}; % init log
ln_idx = 1; % first line index
dbsduino.status(s_idx).msg{ln_idx,1} = ln(1:end-1);
ln_idx = ln_idx+1;

while b.BytesAvailable > 2 && ln_idx < max_lines % keep scanning till all useful lines are there
    ln = fscanf(b);
    if size(ln, 2) > 3
        dbsduino.status(s_idx).msg{ln_idx,1} = ln(2:end-1);
        fprintf([dbsduino.status(s_idx).msg{ln_idx} '\n']);
        ln_idx=ln_idx+1;
    end
    pause(0.010)  % this delay is necessary for DBSduino to catch up
end
fprintf('\n');
flushinput(b)

%% close BT ===============================================================
tic; fclose(b); tt=toc;
fprintf(['Closing BT device for writing took ' num2str(tt) 's\n']);
