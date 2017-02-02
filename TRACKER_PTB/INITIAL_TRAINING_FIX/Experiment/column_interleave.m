function col_interleave = column_interleave(a, b)
    col_interleave = reshape([a(:) b(:)]',2*size(a,1), [])';
end