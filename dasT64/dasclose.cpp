#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{

      double * Out;
      
//        if( Status != NULL){ //frees memory, matlab should clean up
//             mxDestroyArray( (mxArray *) Status);
//             Status = NULL;
//        }
       
       plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
       Out = mxGetPr(plhs[0]);
    
       Out[0] = (double) Das_Clear( );

}
    

