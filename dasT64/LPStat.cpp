#include "mex.h"
#include "string.h"
#include "DasControl.h"

//static mxArray *persistent_array_ptr = NULL;

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    
    /* Check for proper number of arguments */
    if (nrhs != 0) {
         int Pos = (int)mxGetScalar(prhs[0]);
         if(Pos >= 0 && Pos < 6){
                 plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
                 double* val = mxGetPr(plhs[0]);
                 val[0] = Status[Pos];
         }
       
    }else {
         plhs[0] = mxCreateDoubleMatrix(6, 1, mxREAL);
         memcpy((void*)mxGetPr(plhs[0]), (void*)Status, 6*sizeof(double));
        
    }
}