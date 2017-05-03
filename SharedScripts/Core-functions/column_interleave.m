function col_interleave = column_interleave(a, b)
% COLUMN_INTERLEAVE interleave two matrices by column
% See: http://www.peteryu.ca/tutorials/matlab/interleave_matrices
    col_interleave = reshape([a(:) b(:)]',2*size(a,1), [])';
end