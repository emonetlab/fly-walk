%getStopTurnCountNFracPerformMetrics
% S = getStopTurnCountNFracPerformMetrics(S,minTotDist,minTotPath,minTracklen)
% Calculates the paramters related to stops and walks in the given
% Structure S.
%
% S must have the following fields: "expmat" experimental matric and "col"
% defining the column names. The following columns must be calculated and
% defined in "expmat" and "col": 'ArrivedSource', 'time2Source', 'x', 'sx',
% 'y', 'sy','initDistSource','initXPos','stopind','walkind','turnind',
% 'ArrivedSourcePoint', and 'fps'
%
% Estimated statistics are returned in S with the fieldnames:
% 'nStops': number of stops
% 'trackDur': duration of the tracks (sec)
% 'nStopPerSec': number of stops per second 
% 'stopDurTot': total stop durations
% 'stopFrac': fraction of time stopped
% 'nStopPerDisp': number of stops oer unit displacement
% 'nStopPerDispX': number of stops per unit displacemnt in X
% 'nStopPerTravDist': number of stops per unit traveled distance
% 'totDisp': total displacement (mm)
% 'totDispX': total displacement along X
% 'totPath': total traveled distance
% 'nSPSbs': number of stops per second, booth strap estimated
% 'SFbs': fraction of stopped time,booth strap estimated
% 'stopDur': stop durations (sec)
% 'nSPDbs': number of stops per distance, booth strapped
% 'nSPDXbs': number of stops per distance along X, booth strapped
% 'nSPTDbs': number of stops per total traveled distance, booth strapped
% similarly for walks and turns:
% 'nWalks','walkDurTot', 'walkDur', 'walkFrac',
% 'nWalkPerSec','nWalkPerDisp', 'nWalkPerDispX', 'nWalkPerTravDist',
% 'nWPSbs', 'WFbs', 'nWPDbs', 'nWPDXbs', 'nWPTDbs', 'nTurns',
% 'nTurnPerSec', 'turnDurTot', 'turnFrac', 'nTPSbs', 'TFbs', 'turnDur',
% 'nTurnPerDisp', 'nTurnPerDispX', 'nTurnPerTravDist', 'nTPSbs', 'nTPDbs', 
% 'nTPDXbs', 'nTPTDbs'
% Also following estimations:
% 'arrived2Source': source arrival status of the tracks
% 'totDisp2Source': total displacement towards source
% 'DriftSpeed': drift speed, (tot displacement / total time)
% 'XDriftSpeed': drift speed along X
% 'SourceDriftSpeed': drift speed towards source
% And Averages of these: 'AveDriftSpeed', 'AveXDriftSpeed',
% 'AveSourceDriftSpeed', 
% 'DispPerTotPath': displacement to distance ratio
% 'Disp2SourcePerTotPath': displacement toward source to distance ratio
%  And Averages of these: 'AveDispPerTotPath', 'AveDisp2SourcePerTotPath'
% 'ArriveSpeed': arrival speed ((InitDist2Source-SourceRad)./time2Source;)
% 'InitDist2Source': distance between the source radii and the initial
% point of the track (mm)
% 'InitXPos': initial x position of the track
% 'time2Source': time it take for the track to reach to the source radii
% (sec)
% Disp2SourcePerTotPath2Source: obvious
% Path2Source: obvious
% theseTracks: corresponding track numbers in the epmat


function S = getStopTurnCountNFracPerformMetrics(S,minTotDist,minTotPath,minTracklen)
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
SourceRad = S.ConstraintParam.SourceRad; % mm
theseTracks = unique(em(:,1));
arrived2Source = zeros(size(theseTracks));
trackDur = zeros(size(theseTracks));
nStops = zeros(size(theseTracks));
stopDur = cell(size(theseTracks));
stopDurTot = zeros(size(theseTracks));
nWalks = zeros(size(theseTracks));
walkDur = cell(size(theseTracks));
walkDurTot = zeros(size(theseTracks));
totDispX = zeros(size(theseTracks));
totDisp = zeros(size(theseTracks));
totDisp2Source = zeros(size(theseTracks));
totPath = zeros(size(theseTracks));
nTurns = zeros(size(theseTracks));
turnDur = cell(size(theseTracks));
turnDurTot = zeros(size(theseTracks));
time2Source = nan(size(theseTracks));
InitDist2Source = nan(size(theseTracks));
InitXPos = nan(size(theseTracks));
Path2Source = nan(size(theseTracks));

for i = 1:length(theseTracks)
    thisTrack = theseTracks(i);
    emt = em(em(:,1)==thisTrack,:);
    % did it make it to source
    % distance to source
    arrived2Source(i) = emt(1,S.col.ArrivedSource);
    if emt(1,S.col.ArrivedSource)==1
        time2Source(i) = emt(1,S.col.time2Source);
    end
    % calculate total disp towards source
    xi = emt(1,S.col.x)-emt(1,S.col.sx);
    yi = emt(1,S.col.y)-emt(1,S.col.sy);
    xf = emt(end,S.col.x)-emt(end,S.col.sx);
    yf = emt(end,S.col.y)-emt(end,S.col.sy);
    InitDist2Source(i) = emt(1,S.col.initDistSource);
    InitXPos(i) = emt(1,S.col.initXPos);
    totDisp2Source(i) = (xi.^2+yi.^2-xi.*xf-yi.*yf)./(sqrt(xi.^2+yi.^2));
    theseStops = nonzeros(unique(emt(:,S.col.stopind)));
    nStops(i) = length(theseStops);
    theseWalks = nonzeros(unique(emt(:,S.col.walkind)));
    nWalks(i) = length(theseWalks);
    theseTurns = nonzeros(unique(emt(:,S.col.turnind)));
    nTurns(i) = length(theseTurns);
    totDispX(i) = (emt(end,S.col.x)-emt(1,S.col.x));
    totDisp(i) = sqrt((emt(end,S.col.x)-emt(1,S.col.x)).^2+(emt(end,S.col.y)-emt(1,S.col.y)).^2);
    pathInti = getTotPath(emt(:,S.col.x),emt(:,S.col.y));
    totPath(i) = pathInti(end);
    if emt(1,S.col.ArrivedSourcePoint)>0
        % avoid any truncated data
        if length(pathInti)>=emt(1,S.col.ArrivedSourcePoint)
            Path2Source(i) = pathInti(emt(1,S.col.ArrivedSourcePoint));
        end
    end
    trackDur(i) = size(emt,1)/emt(1,S.col.fps);
    
    % duration of stops
    stopduri = zeros(size(theseStops));
    for j = 1:length(theseStops)
        thisStop  = theseStops(j);
        emtj = emt(emt(:,S.col.stopind)==thisStop);
        stopduri(j) = size(emtj,1)/emt(1,S.col.fps);
    end
    stopDur(i) = {stopduri};
    stopDurTot(i) = sum(stopduri);
    
    % duration of walks
    walkduri = zeros(size(theseWalks));
    for j = 1:length(theseWalks)
        thisWalk  = theseWalks(j);
        emtj = emt(emt(:,S.col.walkind)==thisWalk);
        walkduri(j) = size(emtj,1)/emt(1,S.col.fps);
    end
    walkDur(i) = {walkduri};
    walkDurTot(i) = sum(walkduri);
    
    % duration of turns
    turnduri = zeros(size(theseTurns));
    for j = 1:length(theseTurns)
        thisTurn  = theseTurns(j);
        emtj = emt(emt(:,S.col.turnind)==thisTurn);
        turnduri(j) = size(emtj,1)/emt(1,S.col.fps);
    end
    turnDur(i) = {turnduri};
    turnDurTot(i) = sum(turnduri);
    
end

% do some cleaning
if ~isempty(minTracklen)&&~isnan(minTracklen)
    delTheseTrack = trackDur<minTracklen;
end

if ~isempty(minTotPath)&&~isnan(minTotPath)
    delTheseTrack = delTheseTrack + totPath<minTotPath;
end

if ~isempty(minTotDist)&&~isnan(minTotDist)
    delTheseTrack = delTheseTrack + totDisp<minTotDist;
end

arrived2Source(delTheseTrack) = [];
totDisp2Source(delTheseTrack) = [];
trackDur(delTheseTrack) = [];
nStops(delTheseTrack) = [];
stopDur(delTheseTrack) = [];
stopDurTot(delTheseTrack) = [];
nWalks(delTheseTrack) = [];
walkDur(delTheseTrack) = [];
walkDurTot(delTheseTrack) = [];
totDisp(delTheseTrack) = [];
totDispX(delTheseTrack) = [];
totPath(delTheseTrack) = [];
nTurns(delTheseTrack) = [];
turnDur(delTheseTrack) = [];
turnDurTot(delTheseTrack) = [];
time2Source(delTheseTrack) = [];
InitDist2Source(delTheseTrack) = [];
InitXPos(delTheseTrack) = [];
Path2Source(delTheseTrack) = [];
theseTracks(delTheseTrack) = [];


% stops   
nStopPerSec = nStops./trackDur;
stopFrac = stopDurTot./trackDur;
nStopPerDisp = nStops./totDisp;
nStopPerDispX = nStops./totDispX;
nStopPerTravDist = nStops./totPath;

nSPSbs = getBthofData(nStopPerSec,100,.1);
SFbs = getBthofData(stopFrac,100,.1);
nSPDbs = getBthofData(nStopPerDisp,100,.1);
nSPDXbs = getBthofData(nStopPerDispX,100,.1);
nSPTDbs = getBthofData(nStopPerTravDist,100,.1);

% walks
nWalkPerSec = nWalks./trackDur;
walkFrac = walkDurTot./trackDur;
nWalkPerDisp = nWalks./totDisp;
nWalkPerDispX = nWalks./totDispX;
nWalkPerTravDist = nWalks./totPath;

nWPSbs = getBthofData(nWalkPerSec,100,.1);
WFbs = getBthofData(walkFrac,100,.1);
nWPDbs = getBthofData(nWalkPerDisp,100,.1);
nWPDXbs = getBthofData(nWalkPerDispX,100,.1);
nWPTDbs = getBthofData(nWalkPerTravDist,100,.1);

% turns
nTurnPerSec = nTurns./trackDur;
turnFrac = turnDurTot./trackDur;
nTurnPerDisp = nTurns./totDisp;
nTurnPerDispX = nTurns./totDispX;
nTurnPerTravDist = nTurns./totPath;

nTPSbs = getBthofData(nTurnPerSec,100,.1);
TFbs = getBthofData(turnFrac,100,.1);
nTPDbs = getBthofData(nTurnPerDisp,100,.1);
nTPDXbs = getBthofData(nTurnPerDispX,100,.1);
nTPTDbs = getBthofData(nTurnPerTravDist,100,.1);

% calculate drift speed
DriftSpeed = totDisp./trackDur;
XDriftSpeed = totDispX./trackDur;
SourceDriftSpeed = totDisp2Source./trackDur;
ArriveSpeed = (InitDist2Source-SourceRad)./time2Source;


AveDriftSpeed = getBthofData(DriftSpeed,100,.1);
AveXDriftSpeed = getBthofData(XDriftSpeed,100,.1);
AveSourceDriftSpeed = getBthofData(SourceDriftSpeed,100,.1);

DispPerTotPath = totDisp./totPath;
Disp2SourcePerTotPath = totDisp2Source./totPath;
Disp2SourcePerTotPath2Source = (InitDist2Source-SourceRad)./Path2Source;
AveDispPerTotPath = getBthofData(DispPerTotPath,100,.1);
AveDisp2SourcePerTotPath = getBthofData(Disp2SourcePerTotPath,100,.1);

% put the output in the structure
S.nStops = nStops;
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

S.nWalks = nWalks;
S.walkDurTot = walkDurTot;
S.walkDur = walkDur;
S.walkFrac = walkFrac;
S.nWalkPerSec = nWalkPerSec;
S.nWalkPerDisp = nWalkPerDisp;
S.nWalkPerDispX = nWalkPerDispX;
S.nWalkPerTravDist = nWalkPerTravDist;
S.nWPSbs = nWPSbs;
S.WFbs = WFbs;
S.nWPDbs = nWPDbs;
S.nWPDXbs = nWPDXbs;
S.nWPTDbs = nWPTDbs;

S.nTurns = nTurns;
S.nTurnPerSec  = nTurnPerSec;
S.turnDurTot = turnDurTot;
S.turnFrac = turnFrac;
S.nTPSbs = nTPSbs;
S.TFbs = TFbs;
S.turnDur = turnDur;
S.nTurnPerDisp = nTurnPerDisp;
S.nTurnPerDispX = nTurnPerDispX;
S.nTurnPerTravDist = nTurnPerTravDist;
S.nTPSbs = nTPSbs;
S.nTPDbs = nTPDbs;
S.nTPDXbs = nTPDXbs;
S.nTPTDbs = nTPTDbs;

S.arrived2Source = arrived2Source;
S.totDisp2Source = totDisp2Source;
S.DriftSpeed = DriftSpeed;
S.XDriftSpeed = XDriftSpeed;
S.SourceDriftSpeed = SourceDriftSpeed;
S.AveDriftSpeed = AveDriftSpeed;
S.AveXDriftSpeed = AveXDriftSpeed;
S.AveSourceDriftSpeed = AveSourceDriftSpeed;
S.DispPerTotPath = DispPerTotPath;
S.Disp2SourcePerTotPath = Disp2SourcePerTotPath;
S.AveDispPerTotPath = AveDispPerTotPath;
S.AveDisp2SourcePerTotPath = AveDisp2SourcePerTotPath;
S.ArriveSpeed = ArriveSpeed;
S.InitDist2Source= InitDist2Source;
S.InitXPos = InitXPos;
S.time2Source = time2Source;
S.Disp2SourcePerTotPath2Source = Disp2SourcePerTotPath2Source;
S.Path2Source = Path2Source;
S.trackNum = theseTracks;

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