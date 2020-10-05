function totPath = getTotPathExpMat(em,colnumx,colnumy)
%getTotPathExpMat
%  totPath = getTotPathExpMat(em,colnumx,colnumy)
% Calculates the distance each fly travels as a function of time. The total
% path starts as zero and accumulates in time.
%


switch nargin
    case 2
        colnumy = 7; % default y column
    case 1
        colnumy = 7; % default y column
        colnumx = 6; % default y column
end


trackindex = unique(em(:,1));

totPath = nan(size(em(:,1)));

for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    emt = em(em(:,1)==trackindex(tracknum),:);   
    totPath (sind:eind) = getTotPath(emt(:,colnumx),emt(:,colnumy));
end
