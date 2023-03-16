#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    int Bit;
    unsigned short Val;
    double *Out;
    
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
        return;
    }
    
        Bit = (int) mxGetScalar(prhs[0]);
        Val = (unsigned short ) mxGetScalar(prhs[1]);
        
        plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
        Out = mxGetPr(plhs[0]);
    
       Out[0] = (double) DO_Bit( Bit, Val);
       

}
    

