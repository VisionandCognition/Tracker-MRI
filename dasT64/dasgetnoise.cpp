#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    double *avg, *Out;
    
        plhs[0] = mxCreateDoubleMatrix(2, 1, mxREAL);
        Out = mxGetPr(plhs[0]);
        
       avg = get_Noise( );
       Out[0] = avg[0];
       Out[1] = avg[1];
}
    

