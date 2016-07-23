%poststim

global Par

if isfield(Par,'DasOn') && Par.DasOn == 1
 dasclose();
 cgshut
 
end

 Par.DasOn = 0;
 clear all
%  close all
