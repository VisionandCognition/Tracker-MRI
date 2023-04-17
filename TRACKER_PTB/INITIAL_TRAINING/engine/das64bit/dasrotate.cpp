#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   double Angle;

   
    /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required; angle");
        return;
    }
    Angle = (double) mxGetScalar(prhs[0]);
    
    Rotate(Angle);
}