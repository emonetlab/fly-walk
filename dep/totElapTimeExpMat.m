function totElapTime = totElapTimeExpMat(em,tcolnum)
%EndDiffExpMatColumn
% em = EndDiffExpMatColumn(em,colnum)
% calculates the differences of ends [p(end)-p(1)] for each track in the
% expmat.
%
if nargin==1
    tcolnum = 5; % time column
end

trackindex = unique(em(:,1));
totElapTime = zeros(size(em(:,tcolnum)));


for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    % find dt
    dt = mode(diff(em(sind:eind,tcolnum)));
    totElapTime(sind:eind) = length(sind:eind)*dt;
end