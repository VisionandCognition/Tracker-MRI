#include "mex.h"
#include "DasControl.h"


void mexFunction(
				 int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
   unsigned short Sqr;
   int Numwin;
   double* In;
   float* win;
    
    /* Check for proper number of arguments */
    if (nrhs != 3) {
        mexErrMsgTxt("Three input arguments required; Numwindows, winmatrix, shape");
        return;
    }
        Numwin = (int)mxGetScalar(prhs[0]);
        In =  mxGetPr(prhs[1]);
        //maybe I should change this to doubles!!!
        win = new float[ Numwin * 5];
        for(int i = 0; i < Numwin * 5; i++){
            win[i] = (float)In[i];
        }
        
        Sqr = (unsigned short)mxGetScalar(prhs[2]);
//         SCx = (float)mxGetScalar(prhs[3]);
//         SCy = (float)mxGetScalar(prhs[4]);
    
//       Set_Window( Numwin, win, Sqr, SCx, SCy);
       Set_Window(Numwin, win, Sqr);
       
       delete [] win;
}
    

