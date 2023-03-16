#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
      double On;
      double *Pos;
      
          /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
        On = mxGetScalar(prhs[0]); 
              
       plhs[0] = mxCreateDoubleMatrix(2, 1, mxREAL);
       Pos = mxGetPr(plhs[0]);  
       Use_Mouse( (unsigned short)On, Pos);
}
    

