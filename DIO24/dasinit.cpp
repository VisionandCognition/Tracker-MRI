#include "mex.h"
#define WORD unsigned short
#include "IOdas.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
	WORD Board;
    double* Out;
    
    /* Check for proper number of arguments */
    if (nrhs != 1) {
		mexErrMsgTxt("One input argument BoardNum, one output result; 0 is good.");
        return;
    }
    

	plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
	Out = mxGetPr(plhs[0]);

	Board = (WORD)mxGetScalar(prhs[0]);
    
	Out[0] = (double)InitIO(Board);
    
    
}
    

