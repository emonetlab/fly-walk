function [totdisp,meanVar] = getTotDispNVar(x)
%getTotDispNVar
% [totdisp,meanVar] = getTotDispNVar(x) returns the total absolute
% displacement of the given vector:  |x(last)-x(0)|
% the variation in the displacement (meanVar) is also returned. meanVar is
% calculated as the sum of square displacement of each point with respect
% to the mean position: sum((x(i)-xmean)^2)
%

% remove nans
for i = 1:size(x,2)
    x(isnan(x(:,i)),:) = [];
end
if isempty(x)
    meanVar = nan;
    totdisp = nan;
else
    meanVar = sum(var(x));
    totdisp = sqrt(sum((x(end,:) - x(1,:)).^2));
end


