function immask = smooth2dmask(im,ind,wins)

indm(1) = ind(1)-wins;
indm(2) = ind(2)-wins;
indp(1) = ind(1)+wins;
indp(2) = ind(2)+wins;
if ind(1)-wins<1; indm(1) = 1; end
if ind(2)-wins<1; indm(2) = 1; end
if ind(1)+wins>size(im,1); indp(1) = size(im,1); end
if ind(2)+wins>size(im,2); indp(2) = size(im,2); end

immask = NaN(size(im));
immask(indm(1):indp(1),indm(2):indp(2)) = im(indm(1):indp(1),indm(2):indp(2));
