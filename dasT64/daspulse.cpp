#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    unsigned short Rep,  Intvl;

    
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
        return;
    }
    
       Rep = (unsigned short)mxGetScalar(prhs[0]);
       Intvl = (unsigned short)mxGetScalar(prhs[1]);
    
       Pulse( Rep, Intvl);
}
    

