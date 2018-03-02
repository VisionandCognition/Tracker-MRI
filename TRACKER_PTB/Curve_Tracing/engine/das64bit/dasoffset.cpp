#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   float X,  Y;
   ScaleOff SO = {};
   double *OFF;
   
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
        return;
    }
    plhs[0] = mxCreateDoubleMatrix(4, 1, mxREAL);
    OFF = mxGetPr(plhs[0]);   
   
        X = (float)mxGetScalar(prhs[0]);
        Y = (float)mxGetScalar(prhs[1]);
    
       SO = ShiftOffset( X, Y);
       OFF[0] = SO.Offx;
       OFF[1] = SO.Offy;
       OFF[2] = SO.SCx;
       OFF[3] = SO.SCy;       
}
    

