function [polyBoundary,polyEachObject] = mask2polyBoundary(mask)
% returns the fly mask boundaries given as the binary mask
% based on mask2poly by Nikolay S.
% http://www.mathworks.com/matlabcentral/fileexchange/32112-mask2poly
%

% get the individual flies
S = regionprops(mask,'PixelIdxList');

% go over the pieces and get the boundaries
polyBoundary = [];
polyEachObject = cell(size(S));

for i = 1:numel(S)
    maskt = false(size(mask));
    maskt(S(i).PixelIdxList) = true;
    poly = mask2poly(maskt,'exact'); % get boundary pixels
    % delete negative numbers
    poly(poly(:,1)<0,:) = [];
    poly(poly(:,2)<0,:) = [];
%     poly(1,:) = [];
    polyBoundary = [polyBoundary;[NaN,NaN];poly];
    polyEachObject(i) = {poly};
end