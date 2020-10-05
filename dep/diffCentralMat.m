function df = diffCentralMat(x,dim)
%diffCentralMat
% df = diffCentralMat(x,dim) returns the central derivative of matrix x.
% default dimension is 1, assumes column vectors
% last points are assigned as the mean of the fisrt and last two points of
% the central derivative
%
if nargin==1
    dim = 1;
end

% if row differentiation is requested then transpose x
if dim == 2
    x = x';
end

% assert minimum vector length 4
assert(size(x,1)>3,'Vector length has to be at least 4')

% initiate the output
df = zeros(size(x));

for coln = 1:size(x,2)
    df(:,coln) = diffCentral(x(:,coln));
end

% tanspose back if did so
if dim == 2
    df = df';
end