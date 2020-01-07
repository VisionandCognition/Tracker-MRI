% Test the connection with the bluetooth brain stimulator
% PROCEDURE:
%   - Switch on stimulator
%   - Connect with BT on PC

% Show connection info
ShowInfo = true;

%% Using the instrument toolbox ===========================================
% Find available Bluetooth devices
btInfo = instrhwinfo('Bluetooth');
% get info of DBSduino
btDBSduino = instrhwinfo('Bluetooth','DBSduino');
StimChan = str2double(btDBSduino.Channels{1});

% Display the information about the first device discovered
if ShowInfo
    btInfo.RemoteNames{StimChan}
    btInfo.RemoteIDs{StimChan}
end

% Construct a Bluetooth Channel object to the first Bluetooth device
%b = Bluetooth(btInfo.RemoteIDs{StimChan}, 10)
b = Bluetooth(btInfo.RemoteNames{StimChan}, 3)
% optional: switch the terminator (is thois necessary?)
b.Terminator = 'CR'

% Connect the Bluetooth Channel object to the specified remote device
fopen(b)


%Error using icinterface/fopen (line 83)
%Unsuccessful open: Cannot connect to the device. Possible reasons are another application is connected
%or the device is not available. 


% Write some data and query the device for an ascii string
fprintf(b, data);
idn = fscanf(b);

% Disconnect the object from the Bluetooth device
fclose(b);






%% Using bluetooth as serial port =========================================
test = serial('COM3', 'BaudRate', 9600); % Open the port to set the MS amplitude
test.Timeout = 1;
    
fopen(test);
test.RequestToSend = 'on';
fprintf(test, 'B100');

warning off
idn = fscanf(test,'%s');
warning on
if isempty(idn)
    display('/!\ Micro-stimulator seems offline!')
elseif idn == 'OK'
    display('Micro-stimulator appears online')
else
    display('Weird readout, please retry')
end
fclose(test); % important!! 

