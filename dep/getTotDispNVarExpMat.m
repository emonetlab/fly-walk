function [totdisp,meanVar] = getTotDispNVarExpMat(em,colnumx,colnumy)
%getTotDispNVarExpMat
% [totdisp,meanVar] = getTotDispNVarExpMat(em,colnumx,colnumy)
% Calculates  the abs displacement: |x(last)-x(0)| and variance of each
% track in the experimental matrix (expmat)
%


switch nargin
    case 2
        colnumy = 7; % default y column
    case 1
        colnumy = 7; % default y column
        colnumx = 6; % default y column
end


trackindex = unique(em(:,1));

totdisp = nan(size(em(:,1)));
meanVar = nan(size(em(:,1)));

for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    
    emt = em(em(:,1)==trackindex(tracknum),:);
    xtemp = [emt(:,colnumx),emt(:,colnumy)];
    [totdispi,meanVari] = getTotDispNVar(xtemp);
    
    totdisp (sind:eind) = totdispi;
    meanVar(sind:eind) = meanVari;
end

