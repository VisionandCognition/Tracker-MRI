#include "mex.h"
#include "DasControl.h"

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
       double *raw;
       
       //Output 
       plhs[0] = mxCreateDoubleMatrix(2, 1, mxREAL);
       raw = mxGetPr(plhs[0]);  
        
       SetZero( raw );
       
}
    

