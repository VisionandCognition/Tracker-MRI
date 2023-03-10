
p = mfilename('fullpath');
p = replace(p,'\dascompile64','');

disp('dasrotate')
mex(['-L' p ], '-lDasControl', 'dasrotate.cpp' )

disp('dassetscale')
mex(['-L' p ], '-lDasControl', 'dasscale.cpp' )

disp('dasinit')
mex(['-L' p ], '-lDasControl', 'dasinit.cpp' )

disp('dasreset')
mex( ['-L' p ], '-lDasControl', 'dasreset.cpp' )

disp('LPStat')
mex( ['-L' p ], '-lDasControl', 'LPStat.cpp' )

disp('daspause')
mex( ['-L' p ], '-lDasControl', 'daspause.cpp' )

disp('daspulse')
mex( ['-L' p ], '-lDasControl', 'daspulse.cpp' )

disp('daszero')
mex( ['-L' p ], '-lDasControl', 'daszero.cpp' )

disp('dasoffset')
mex( ['-L' p ], '-lDasControl', 'dasoffset.cpp' )

disp('dasrun')
mex( ['-L' p ], '-lDasControl', 'dasrun.cpp' )

disp('dasgeteye')
mex( ['-L' p ], '-lDasControl', 'dasgeteye.cpp' )

disp('dasgetnoise')
mex( ['-L' p ], '-lDasControl', 'dasgetnoise.cpp' )

disp('dassetnoise')
mex( ['-L' p ], '-lDasControl', 'dassetnoise.cpp' )

disp('dasgetlevel')
mex( ['-L' p ], '-lDasControl', 'dasgetlevel.cpp' )

disp('dassetwindow')
mex( ['-L' p ], '-lDasControl', 'dassetwindow.cpp' )

disp('dasgetcursorpos')
mex( ['-L' p ], '-lDasControl', 'dasgetcursorpos.cpp' )

disp('dasgetposition')
mex( ['-L' p ], '-lDasControl', 'dasgetposition.cpp' )

disp('dasusemouse')
mex( ['-L' p ], '-lDasControl', 'dasusemouse.cpp' )

disp('dasclose')
mex( ['-L' p ], '-lDasControl', 'dasclose.cpp' )

disp('dasword')
mex( ['-L' p ], '-lDasControl', 'dasword.cpp' )

disp('dasclearword')
mex( ['-L' p ], '-lDasControl', 'dasclearword.cpp' )

disp('daspulse')
mex( ['-L' p ], '-lDasControl', 'dasbit.cpp' )

disp('dasjuice')
mex( ['-L' p ], '-lDasControl', 'dasjuice.cpp' )

disp('dasanalogout')
mex( ['-L' p ], '-lDasControl', 'dasanalogout.cpp' )

disp('dasgettrace')
mex( ['-L' p ], '-lDasControl', 'dasgettrace.cpp' )
