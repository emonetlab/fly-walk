function df = diffBwd(x)
%diffBwd
% df = diffBwd(x) returns the backward derivative of vector x. The first point 
% is assigned as the mean of the first two points of the forward derivative
%
assert(length(x)>1,'Vector length has to be at least 2')
df = zeros(size(x));
dft = (x(2:end)-x(1:end-1));
% assign the fisrt point as mean of the first two points
df(2:end) = dft;
df(1) = mean(dft(1:2));