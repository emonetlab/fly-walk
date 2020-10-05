function df = anglediffFwd(x)
%anglediffFwd
% df = anglediffFwd(x) returns the forward derivative of angle vector x. Last point 
% is assigned as the mean of the last two points of the forward derivative
% inputs and output is degree
%
assert(length(x)>1,'Vector length has to be at least 2')
df = zeros(size(x));
dft = angleDiffVec(x(2:end),x(1:end-1));
% assign last point as mean of the last two points
df(1:end-1) = dft;
df(end) = meanOrientation(dft(end-1:end));