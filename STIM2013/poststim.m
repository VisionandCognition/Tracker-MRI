%poststim

global Par
%global LPStat

if isfield(Par,'DasOn') && Par.DasOn == 1
 dasclose();
 cgshut
 
end

 Par.DasOn = 0;
%  clear global LPStat
  clear all
%  close all
