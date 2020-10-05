function [m2d,mind] = hist2d(x,y,xedges,yedges)

% this function calulates 2D histogram of given x y vectors in bins defined
% by xedges and yedges. m2d is the calculated 2D histogram and mind is the
% cell structure conatining the indexes corresponding to the count

% initiate the matrices
m2d = zeros(length(yedges)-1,length(xedges)-1);
mind = cell(length(yedges)-1,length(xedges)-1);

% start with x edges and get y bins counts
[~,~,ind] = histcounts(x,xedges);

% loop over the x bins
for xbin = 1:length(xedges)-1
    Ix = find(xbin==ind);
    [m2d(:,xbin),~,yind] = histcounts(y(Ix),yedges);
    % now sort the indexes
    if ~isempty(Ix)% figure out which one is less
        if length(Ix)<length(yedges)
            for jj = 1:length(Ix)
                mind(yind(jj),xbin) = {[mind{yind(jj),xbin};Ix(jj)]}; 
            end
        else 
            for jj = 1:length(yedges)-1
                Iy = jj==yind;
                mind(jj,xbin) = {Ix(Iy)};
            end
        end
   end
end