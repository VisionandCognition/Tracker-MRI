#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    double *eye;
    
        plhs[0] = mxCreateDoubleMatrix(2, 1, mxREAL);
        eye = mxGetPr(plhs[0]);        
        get_Eye(eye );

}
    

