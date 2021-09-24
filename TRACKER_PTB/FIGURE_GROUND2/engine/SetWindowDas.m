function SetWindowDas()
    global Par
    NumWins = size(Par.WIN, 2);
    WIN = Par.WIN;
    
    dassetwindow( NumWins, WIN(:), Par.Bsqr, Par.SCx*Par.xdir, Par.SCy*Par.ydir )
    %1st: number of control windows
    %2nd: Parameters of position, width and height
    %3rd: bool; square (1) or ellips (0) ; target areas are square or elliptic
    %4th: eyetrace scaling in x direction
    %5th: eytrace scaling in y direction
