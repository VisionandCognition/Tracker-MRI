#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{

    double *outMatrix; 
  //  C=(float*)mxGetData(plhs[0]= mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL ));//mxCreateDoubleMatrix(1,5,mxREAL)); mxSINGLE_CLASS
    /* create the output matrix */
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);

    /* get a pointer to the real data in the output matrix */
        outMatrix = mxGetPr(plhs[0]);
        
        npersistent = 2;
        outMatrix[0] = (double)npersistent;
}
    

