#include "mex.h"
#include "DasControl.h"

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   float Scx,  Scy;
 
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
        return;
    }
    
    Scx = (float)mxGetScalar(prhs[0]);
    Scy = (float)mxGetScalar(prhs[1]);
    
   setScale( Scx, Scy);     
}
    

