#include "mex.h"
#include "DasControl.h"

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   float X,  Y;
 
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
        return;
    }
    
    X = (float)mxGetScalar(prhs[0]);
    Y = (float)mxGetScalar(prhs[1]);
    
   ShiftOffset( X, Y);     
}
    

