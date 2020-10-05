function indmat = getindmat(imsize,ind,wins)

% generates the index matrix for 2d averaging. the output of this function
% is the min and max indexes for i and j so that the part of the matrix can
% be cropped for operation such as mean or median averaging
% imsize = [row,column];
% ind = [ri,ci];
% wins: positive less than min(row, column);
% indmat: (indmr indmc ; indpr indpc)
if wins<0
    wins = 0;
elseif wins>min(imsize)
    wins = min(imsize);
end

indm(1) = ind(1)-wins;
indm(2) = ind(2)-wins;
indp(1) = ind(1)+wins;
indp(2) = ind(2)+wins;
if ind(1)-wins<1; indm(1) = 1; end
if ind(2)-wins<1; indm(2) = 1; end
if ind(1)+wins>imsize(1); indp(1) = imsize(1); end
if ind(2)+wins>imsize(2); indp(2) = imsize(2); end

indmat = [indm;indp];