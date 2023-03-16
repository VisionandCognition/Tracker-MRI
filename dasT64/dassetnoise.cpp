#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    bool Set;
    
    if (nrhs != 1) {
        mexErrMsgTxt("One input required: (0 or 1)");
        return;
    }
    
       Set = (bool)mxGetScalar(prhs[0]);
       set_Noise( Set );
}
    

