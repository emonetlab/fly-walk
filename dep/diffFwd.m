function df = diffFwd(x)
%diffFwd
% df = diffFwd(x) returns the forward derivative of vector x. Last point 
% is assigned as the mean of the last two points of the forward derivative
%
assert(length(x)>1,'Vector length has to be at least 2')
df = zeros(size(x));
dft = (x(2:end)-x(1:end-1));
% assign last point as mean of the last two points
df(1:end-1) = dft;
df(end) = mean(dft(end-1:end));