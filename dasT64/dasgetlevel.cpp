#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    double *level;
    
        plhs[0] = mxCreateDoubleMatrix(nChans-2, 1, mxREAL);
        level = mxGetPr(plhs[0]);        
        get_Level(level);
}
    

