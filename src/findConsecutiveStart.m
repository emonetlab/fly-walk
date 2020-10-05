function ConsStart = findConsecutiveStart(series,NConsec,howmany)
% returns the element of the series that is consecutive by NConsec
if nargin<3
    howmany = 1;
end
 x = diff(series)==1; % these are consecutive numbers
 f = find([false,x]~=[x,false]); % shift up and down, thefore only consecutive parts will match, this will give start and end points of the consecutive pathches
 g = find(f(2:2:end)-f(1:2:end-1)>=NConsec,howmany,'first'); % get lengths 
 ConsStart = series(f(2*g-1)); % First t followed by >=N consecutive numbers