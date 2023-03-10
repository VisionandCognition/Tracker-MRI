#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
      double *Pos;
      
       plhs[0] = mxCreateDoubleMatrix(2, 1, mxREAL);
       Pos = mxGetPr(plhs[0]);    
       get_Cursor_Pos(Pos);

}
    

