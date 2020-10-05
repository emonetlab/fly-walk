function meancos = MeanCos(theta,normalize)
% return the average of the cosine of the angles between vector pairs 

assert(length(theta)>2,'needs at least a pair')

if nargin==1
    normalize = 1;  % get the mean
end
    
% get combinations and do the math
thind = 1:length(theta); % theta indices
combpairs = combnk(thind,2);

meancos = 0;

for i = 1:length(combpairs)
    [xa,ya]=pol2cart(theta(combpairs(i,1)),1);
    [xb,yb]=pol2cart(theta(combpairs(i,2)),1);
    meancos = meancos + xa*xb+ya*yb;
end
if normalize
    meancos = meancos/length(combpairs);
end
    

