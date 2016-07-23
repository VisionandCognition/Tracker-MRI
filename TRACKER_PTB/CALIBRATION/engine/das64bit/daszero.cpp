#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    double *OFF;
    ScaleOff SO = {};
    
    plhs[0] = mxCreateDoubleMatrix(4, 1, mxREAL);
    OFF = mxGetPr(plhs[0]);
    
    SO = SetZero( );
    OFF[0] = SO.Offx;
    OFF[1] = SO.Offy;
    OFF[2] = SO.SCx;
    OFF[3] = SO.SCy; 
}
    

