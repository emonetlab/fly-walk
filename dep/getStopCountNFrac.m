function S = getStopCountNFrac(S,minTotDist,minTotPath,minTracklen,SourceRad)
switch nargin
    case 4
        SourceRad = 20; % mm, source reach boundary
    case 3
        SourceRad = 20; % mm, source reach boundary
        minTracklen = '';
    case 2
        SourceRad = 20; % mm, source reach boundary
        minTotPath = '';
        minTracklen = '';
    case 1
        SourceRad = 20; % mm, source reach boundary
        minTotDist = '';
        minTotPath = '';
        minTracklen = '';
end
        

em = S.expmat;
arrived2Source = zeros(size(theseTracks));
theseTracks = unique(em(:,1));
nTracks = zeros(size(theseTracks));
trackDur = zeros(size(theseTracks));
stopDur = cell(size(theseTracks));
stopDurTot = zeros(size(theseTracks));
totDispX = zeros(size(theseTracks));
totDisp = zeros(size(theseTracks));
totDisp2Source = zeros(size(theseTracks));
totPath = zeros(size(theseTracks));


for i = 1:length(theseTracks)
    thisTrack = theseTracks(i);
    emt = em(em(:,1)==thisTrack,:);
    % did it make it to source
    % distance to source
    dist2Source = sqrt((emt(:,S.col.x)-emt(:,S.col.sx)).^2+(emt(:,S.col.y)-emt(1,S.col.sy)).^2);
    arrived2Source(i) = any(dist2Source<SourceRad);
    % calculate total disp towards source
    xi = emt(1,S.col.x)-emt(1,S.col.sx);
    yi = emt(1,S.col.y)-emt(1,S.col.sy);
    xf = emt(end,S.col.x)-emt(end,S.col.sx);
    yf = emt(end,S.col.y)-emt(end,S.col.sy);
    totDisp2Source(i) = (xi.^2+yi.^2-xi.*xf-yi.*yf)./(sqrt(xi.^2+yi.^2));
    theseStops = nonzeros(unique(emt(:,S.col.stopind)));
    nTracks(i) = length(theseStops);
    totDispX(i) = abs(emt(end,S.col.x)-emt(1,S.col.x));
    totDisp(i) = sqrt((emt(end,S.col.x)-emt(1,S.col.x)).^2+(emt(end,S.col.y)-emt(1,S.col.y)).^2);
    pathInti = getTotPath(emt(:,S.col.x),emt(:,S.col.y));
    totPath(i) = pathInti(end);
    trackDur(i) = size(emt,1)/emt(1,S.col.fps);
    stopduri = zeros(size(theseStops));
    for j = 1:length(theseStops)
        thisStop  = theseStops(j);
        emtj = emt(emt(:,S.col.stopind)==thisStop);
        stopduri(j) = size(emtj,1)/emt(1,S.col.fps);
    end
%     stopDur(i) = {nonzeros(unique(emt(:,S.col.stopDur)))};
% stopDurTot(i) = sum(nonzeros(unique(emt(:,S.col.stopDur))));
    stopDur(i) = {stopduri};
    stopDurTot(i) = sum(stopduri);
    
end

% do some cleaning
if ~isempty(minTracklen)&&~isnan(minTracklen)
    delTheseTrack = trackDur<minTracklen;
%     arrived2Source(delTheseTrack) = [];
%     totDisp2Source(delTheseTrack) = [];
%     nTracks(delTheseTrack) = [];
%     trackDur(delTheseTrack) = [];
%     stopDurTot(delTheseTrack) = [];
%     totDisp(delTheseTrack) = [];
%     totDispX(delTheseTrack) = [];
%     totPath(delTheseTrack) = [];
end

if ~isempty(minTotPath)&&~isnan(minTotPath)
    delTheseTrack = delTheseTrack + totPath<minTotPath;
%     arrived2Source(delTheseTrack) = [];
%     totDisp2Source(delTheseTrack) = [];
%     nTracks(delTheseTrack) = [];
%     trackDur(delTheseTrack) = [];
%     stopDurTot(delTheseTrack) = [];
%     totDisp(delTheseTrack) = [];
%     totDispX(delTheseTrack) = [];
%     totPath(delTheseTrack) = [];
end

if ~isempty(minTotDist)&&~isnan(minTotDist)
    delTheseTrack = delTheseTrack + totDisp<minTotDist;
%     arrived2Source(delTheseTrack) = [];
%     totDisp2Source(delTheseTrack) = [];
%     nTracks(delTheseTrack) = [];
%     trackDur(delTheseTrack) = [];
%     stopDurTot(delTheseTrack) = [];
%     totDisp(delTheseTrack) = [];
%     totDispX(delTheseTrack) = [];
%     totPath(delTheseTrack) = [];
end

arrived2Source(delTheseTrack) = [];
totDisp2Source(delTheseTrack) = [];
nTracks(delTheseTrack) = [];
trackDur(delTheseTrack) = [];
stopDurTot(delTheseTrack) = [];
totDisp(delTheseTrack) = [];
totDispX(delTheseTrack) = [];
totPath(delTheseTrack) = [];
    

nStopPerSec = nTracks./trackDur;
stopFrac = stopDurTot./trackDur;
nStopPerDisp = nTracks./totDisp;
nStopPerDispX = nTracks./totDispX;
nStopPerTravDist = nTracks./totPath;

nSPSbs = getBthofData(nStopPerSec,100,.1);
SFbs = getBthofData(stopFrac,100,.1);
nSPDbs = getBthofData(nStopPerDisp,100,.1);
nSPDXbs = getBthofData(nStopPerDispX,100,.1);
nSPTDbs = getBthofData(nStopPerTravDist,100,.1);

% put the output in the structure
S.nTracks = nTracks;
S.trackDur = trackDur;
S.nStopPerSec  = nStopPerSec;
S.stopDurTot = stopDurTot;
S.stopFrac = stopFrac;
S.nStopPerDisp = nStopPerDisp;
S.nStopPerDispX = nStopPerDispX;
S.nStopPerTravDist = nStopPerTravDist;
S.totDisp = totDisp;
S.totDispX = totDispX;
S.totPath =totPath;
S.nSPSbs = nSPSbs;
S.SFbs = SFbs;
S.stopDur = stopDur;
S.nSPDbs = nSPDbs;
S.nSPDXbs = nSPDXbs;
S.nSPTDbs = nSPTDbs;

end


function bth = getBthofData(data,nboot,throwPerc)
    bth = zeros(2,1);
    sp = zeros(nboot,1);
    for j = 1:nboot
        stopi = datasample(data,round(length(data)*(1-throwPerc)));
        sp(j) = nanmean(stopi);
    end
    bth(1) = mean(sp);
    bth(2) = std(sp)/sqrt(nboot);
end