#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   unsigned short Pause;

    
    /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
    
       Pause = (unsigned short)mxGetScalar(prhs[0]);
    
       Das_Pause( Pause );
}
    

