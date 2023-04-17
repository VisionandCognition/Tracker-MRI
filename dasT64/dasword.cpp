#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
      unsigned short Val;
      double * Out;
      
          /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
        Val = (unsigned short) mxGetScalar(prhs[0]); 
              
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       Out = mxGetPr(plhs[0]);
    
       Out[0] = (double) DO_Word( Val);

}
    

