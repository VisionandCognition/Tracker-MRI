% Test the connection with the bluetooth brain stimulator




%% Using the instrument toolbox ===========================================
% NB! This will only work on Windows 64bit 

% Find available Bluetooth devices
btInfo = instrhwinfo('Bluetooth')

% Display the information about the first device discovered
btInfo.RemoteNames(1)
btInfo.RemoteIDs(1)

% Construct a Bluetooth Channel object to the first Bluetooth device
b = Bluetooth('DBSduino', 3)
b.Terminator = 'CR'

% Connect the Bluetooth Channel object to the specified remote device
fopen(b)


%Error using icinterface/fopen (line 83)
%Unsuccessful open: Cannot connect to the device. Possible reasons are another application is connected
%or the device is not available. 

instrhwinfo('Bluetooth','DBSduino')

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

