#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    float Volt;

    double *Out;
    
    /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
    
        Volt = (float) mxGetScalar(prhs[0]);
        
        plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
        Out = mxGetPr(plhs[0]);
    
       Out[0] = (double) Anaout( Volt );
       

}
    

