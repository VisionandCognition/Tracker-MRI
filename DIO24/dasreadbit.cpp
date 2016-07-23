#include "mex.h"
#define WORD unsigned short
#include "IOdas.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    int Bit;
    WORD Val;
    double *Out;
    
    /* Check for proper number of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
        return;
    }
    
    Bit = (int) mxGetScalar(prhs[0]);    
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    Out = mxGetPr(plhs[0]);
    Val = Readbit(Bit);    
    *Out = (double)Val;

}
    

