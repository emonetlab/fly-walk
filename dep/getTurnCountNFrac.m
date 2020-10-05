function S = getTurnCountNFrac(S,minTotDist,minTotPath,minTracklen)
switch nargin
    case 3
        minTracklen = '';
    case 2
        minTotPath = '';
        minTracklen = '';
    case 1
        minTotDist = '';
        minTotPath = '';
        minTracklen = '';
end
     

em = S.expmat;
theseTracks = unique(em(:,1));
nTracks = zeros(size(theseTracks));
trackDur = zeros(size(theseTracks));
turnDur = cell(size(theseTracks));
turnDurTot = zeros(size(theseTracks));
totDispX = zeros(size(theseTracks));
totDisp = zeros(size(theseTracks));
totPath = zeros(size(theseTracks));

for i = 1:length(theseTracks)
    thisTrack = theseTracks(i);
    emt = em(em(:,1)==thisTrack,:);
    theseTurns = nonzeros(unique(emt(:,S.col.turnind)));
    nTracks(i) = length(theseTurns);
    totDispX(i) = abs(emt(end,S.col.x)-emt(1,S.col.x));
    totDisp(i) = sqrt((emt(end,S.col.x)-emt(1,S.col.x)).^2+(emt(end,S.col.y)-emt(1,S.col.y)).^2);
    pathInti = getTotPath(emt(:,S.col.x),emt(:,S.col.y));
    totPath(i) = pathInti(end);
    trackDur(i) = size(emt,1)/emt(1,S.col.fps);
    turnduri = zeros(size(theseTurns));
    for j = 1:length(theseTurns)
        thisTurn  = theseTurns(j);
        emtj = emt(emt(:,S.col.turnind)==thisTurn);
        turnduri(j) = size(emtj,1)/emt(1,S.col.fps);
    end
%     turnDur(i) = {nonzeros(unique(emt(:,S.col.turnDur)))};
% turnDurTot(i) = sum(nonzeros(unique(emt(:,S.col.turnDur))));
    turnDur(i) = {turnduri};
    turnDurTot(i) = sum(turnduri);
    
end

% do some cleaning
if ~isempty(minTracklen)&&~isnan(minTracklen)
    delTheseTrack = trackDur<minTracklen;
    nTracks(delTheseTrack) = [];
    trackDur(delTheseTrack) = [];
    turnDurTot(delTheseTrack) = [];
    totDisp(delTheseTrack) = [];
    totDispX(delTheseTrack) = [];
    totPath(delTheseTrack) = [];
end

if ~isempty(minTotPath)&&~isnan(minTotPath)
    delTheseTrack = totPath<minTotPath;
    nTracks(delTheseTrack) = [];
    trackDur(delTheseTrack) = [];
    turnDurTot(delTheseTrack) = [];
    totDisp(delTheseTrack) = [];
    totDispX(delTheseTrack) = [];
    totPath(delTheseTrack) = [];
end

if ~isempty(minTotDist)&&~isnan(minTotDist)
    delTheseTrack = totDisp<minTotDist;
    nTracks(delTheseTrack) = [];
    trackDur(delTheseTrack) = [];
    turnDurTot(delTheseTrack) = [];
    totDisp(delTheseTrack) = [];
    totDispX(delTheseTrack) = [];
    totPath(delTheseTrack) = [];
end

nTurnPerSec = nTracks./trackDur;
turnFrac = turnDurTot./trackDur;
nTurnPerDisp = nTracks./totDisp;
nTurnPerDispX = nTracks./totDispX;
nTurnPerTravDist = nTracks./totPath;

nTPSbs = getBthofData(nTurnPerSec,100,.1);
TFbs = getBthofData(turnFrac,100,.1);
nTPDbs = getBthofData(nTurnPerDisp,100,.1);
nTPDXbs = getBthofData(nTurnPerDispX,100,.1);
nTPTDbs = getBthofData(nTurnPerTravDist,100,.1);

% put the output in the structure
S.nTracks = nTracks;
S.trackDur = trackDur;
S.nTurnPerSec  = nTurnPerSec;
S.turnDurTot = turnDurTot;
S.turnFrac = turnFrac;
S.nTPSbs = nTPSbs;
S.TFbs = TFbs;
S.turnDur = turnDur;
S.nTurnPerDisp = nTurnPerDisp;
S.nTurnPerDispX = nTurnPerDispX;
S.nTurnPerTravDist = nTurnPerTravDist;
S.totDisp = totDisp;
S.totDispX = totDispX;
S.totPath =totPath;
S.nTPSbs = nTPSbs;
S.nTPDbs = nTPDbs;
S.nTPDXbs = nTPDXbs;
S.nTPTDbs = nTPTDbs;

end


function bth = getBthofData(data,nboot,throwPerc)
    bth = zeros(2,1);
    sp = zeros(nboot,1);
    for j = 1:nboot
        turni = datasample(data,round(length(data)*(1-throwPerc)));
        sp(j) = nanmean(turni);
    end
    bth(1) = mean(sp);
    bth(2) = std(sp)/sqrt(nboot);
end