function m2d = mean2d(var,mind,cutoff)
switch nargin
    case 2
        cutoff = 0;
end

% averages the varibale given as var in the 2D matrix whose indices are
% given by mind. mind is output of hist2d. if there are no indexes in any
% element of mind a NaN will be assigned
% m2d = NaN(size(mind));  % initialize m2d
m2d = zeros(size(mind));  % initialize m2d

% loop over mind and get averages
for i = 1:length(mind(:))
    vart = var(mind{i});
    % remove Nans
    vart(isnan(vart))=[];
    if cutoff>0
        vart = vart(vart>=cutoff);
    end
    if ~isempty(vart)
        m2d(i) = mean(vart);
    end
end