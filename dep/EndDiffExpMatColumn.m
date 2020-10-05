function diffcol = EndDiffExpMatColumn(em,colnum)
%EndDiffExpMatColumn
% em = EndDiffExpMatColumn(em,colnum)
% calculates the differences of ends [p(end)-p(1)] for each track in the
% expmat.
%

trackindex = unique(em(:,1));
diffcol = zeros(size(em(:,colnum)));


for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    diffcol(sind:eind) = em(eind,colnum)-em(sind,colnum);
end