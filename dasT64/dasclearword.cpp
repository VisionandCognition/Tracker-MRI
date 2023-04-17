#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
      double * Out;
                    
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       Out = mxGetPr(plhs[0]);
    
       Out[0] = (double) Clear_Word( );

}
    

