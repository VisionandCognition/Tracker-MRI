#include "mex.h"
#include "DasControl.h"

//static mxArray *persistent_array_ptr = NULL;

void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
    int Board,  Nchan;

    
    /* Check for proper number of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments (Board, Numchannels), one output.");
        return;
    }
    
    //allocate persistent memory for status pointer 
  //  if (Status != NULL){ //if status not empty
 //       mxSetPr(plhs[0], Status);//if status is not empty
  //      mexPrintf("MEX-file reusing array\n");

 //   } else {
  //      plhs[0] = mxCreateDoubleMatrix(10, 1, mxREAL);
       
        //status is a pointer in the Dll, points to allocated memory
//        Status = mxGetPr(plhs[0]);  //return status (pointer lefthand side)
 //   }
    
    Board = (int)mxGetScalar(prhs[0]);
    Nchan = (int)mxGetScalar(prhs[1]);
    
    Das_Init( Board, Nchan);
    
    
}
    

