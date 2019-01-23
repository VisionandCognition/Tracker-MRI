function db = nhi_fyd_VCparms()

%database parameters
db.User = 'dbuser';
db.Passw = 'SoUrhy8nEmMQk51Q';
db.Database = 'roelfsemalab';
db.Server = 'nhi-fyd';
db.Tbl = 'sessions';
db.Fields = { 'project', 'dataset', 'subject', 'stimulus', ...
    'excond', 'setup', 'date', 'sessionid',  ...
    'investid', 'logfile', 'url', 'server'};