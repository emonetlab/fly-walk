function df = diffCentral(x)
%diffCentral
% df = diffCentral(x) returns the central derivative of vector x. First and
% last points are assigned as the mean of the fisrt and last two points of
% the central derivative
%
assert(length(x)>3,'Vector length has to be at least 4')
df = zeros(size(x));
dft = (x(3:end)-x(1:end-2))/2;
% assign end point as mean of the two points at both ends
df(2:end-1) = dft;
df(1) = mean(dft(1:2));
df(end) = mean(dft(end-1:end));