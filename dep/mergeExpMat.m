function em = mergeExpMat(em1,em2)
% merges experimental matrixes into a single experimental matrix
% the last column is assumed to be the file index

assert(size(em1,2)==size(em2,2),'matrixes must have same number of column')

em = [em1;em2];
em(size(em1,1)+1:end,1) = em(size(em1,1)+1:end,1) + em1(end,1);
em(size(em1,1)+1:end,2) = em(size(em1,1)+1:end,2) + em1(end,2);
em(size(em1,1)+1:end,end) = em(size(em1,1)+1:end,end) + em1(end,end);