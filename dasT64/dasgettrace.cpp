

#include "mex.h"
#include "DasControl.h"

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    double * trace;
    
    plhs[0] = mxCreateDoubleMatrix(1024, nChans, mxREAL);
    trace = mxGetPr(plhs[0]);
      
    get_Rawtrace(trace);
    
}