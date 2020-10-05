function df = anglediffCentral(x)
%anglediffCentral
% df = anglediffCentral(x) returns the central derivative of angle vector x.
% First and last points are assigned as the mean of the fisrt and last two
% points of the central derivative
% inputs and output is degree
%
assert(length(x)>3,'Vector length has to be at least 3')
df = zeros(size(x));
dft = angleDiffVec(x(3:end),x(1:end-2))/2;
% assign end point as mean of the two points at both ends
df(2:end-1) = dft;
df(1) = meanOrientation(dft(1:2));
df(end) = meanOrientation(dft(end-1:end));