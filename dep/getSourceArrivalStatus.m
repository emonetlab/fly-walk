function stemp = getSourceArrivalStatus(stemp,SourceRad)
% calculates if the tracks in stemp reach to the sourcw within SourceRad

% set/fix the column and the col
stemp = getSetNfixColumnExpmat(stemp);

% create additional necessary columns
addFields ={'ArrivedSource', 'ArrivedSourcePoint', 'time2Source','initDistSource', 'initXPos'};
for i = 1:numel(addFields)
    stemp = createNAppendColumn2Expmat(stemp,addFields{i});
end

if nargin == 1
    SourceRad = 15;
end

em = stemp.expmat;
theseTracks = unique(em(:,1));

for i = 1:length(theseTracks)
    thisTrack = theseTracks(i);
    emt = em(em(:,1)==thisTrack,:);
    % did it make it to source
    % distance to source
    dist2Source = sqrt((emt(:,stemp.col.x)-emt(:,stemp.col.sx)).^2+(emt(:,stemp.col.y)-emt(1,stemp.col.sy)).^2);
    stemp.expmat(em(:,1)==thisTrack,stemp.col.ArrivedSource) = any(dist2Source<SourceRad);
    stemp.expmat(em(:,1)==thisTrack,stemp.col.initDistSource) = dist2Source(1);
    stemp.expmat(em(:,1)==thisTrack,stemp.col.initXPos) = emt(1,stemp.col.x);
    if any(dist2Source<SourceRad)
        % calculate time to the source
        stemp.expmat(em(:,1)==thisTrack,stemp.col.time2Source) = find(dist2Source<SourceRad,1)/emt(1,stemp.col.fps);
        stemp.expmat(em(:,1)==thisTrack,stemp.col.ArrivedSourcePoint) = find(dist2Source<SourceRad,1);
    end
end
end