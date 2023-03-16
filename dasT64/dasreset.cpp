#include "mex.h"
#include "DasControl.h"

 
void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    int In;
  //  double *Status;
    
    /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
    
        In = (int)mxGetScalar(prhs[0]);
     //   plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        
       // Status = Reset_Status( In);
        Reset_Status( In);
    //    mxSetPr(plhs[0], Status);
    //    mxSetM(plhs[0], 10);
    //    mxSetN(plhs[0], 1);

}
    

