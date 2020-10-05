function df = anglediffBwd(x)
%anglediffBwd
% df = anglediffBwd(x) returns the backward derivative of angle vector x. The first point 
% is assigned as the mean of the first two points of the forward derivative
% inputs and output is degree
%
assert(length(x)>1,'Vector length has to be at least 2')
df = zeros(size(x));
dft = angleDiffVec(x(2:end),x(1:end-1));
% assign the fisrt point as mean of the first two points
df(2:end) = dft;
df(1) = meanOrientation(dft(1:2));