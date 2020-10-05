function [turnInd,nturn,turnFrac,turnDur,turnTotDur] = getTurnExpMat(em,colNumTurn,colNumFps,elimboutlen)
%getTurnExpMat
% [turnInd,nturn,turnFrac,turnDur,turnTotDur] = getTurnExpMat(em,colNumTurn,colNumFps,elimboutlen)
% Calculates the indexes for turn bouts, the durations for these
% bouts, the total durations of theturns as wel as number of turns
% default  turn column is assumed to be the last column
% default fps column is 20
%

switch nargin
    case 3
        elimboutlen = .1;    % sec
    case 2
        elimboutlen = .1;    % sec
        colNumFps = 20;
    case 1
        elimboutlen = .1;    % sec
        colNumFps = 20;
        colNumTurn = size(em,2);
end

trackindex = unique(em(:,1));
turnInd = zeros(size(em(:,1)));
nturn = zeros(size(em(:,1)));
turnDur = zeros(size(em(:,1)));
turnFrac = zeros(size(em(:,1)));
turnTotDur = zeros(size(em(:,1)));

for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    emt = em(sind:eind,:);
    expind = em(sind,2);
    fps = mode(em(em(:,2)==expind,colNumFps));
    
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colNumTurn)>0));
    % eliminate single point noTurns
    if isempty(p) || isempty(n)
        continue
    end
    noTurnlen = (p(2:end)-n(1:end-1));
    thesenoTurnBouts = n(noTurnlen<=(elimboutlen*fps));
    thesenoTurnLen = noTurnlen(noTurnlen<=(elimboutlen*fps));
    for wbind = 1:length(thesenoTurnLen)
        emt(thesenoTurnBouts(wbind)+1:thesenoTurnBouts(wbind)+thesenoTurnLen(wbind),colNumTurn) = 1;
    end
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colNumTurn)>0));
    % eliminate single point turns
    turnlen = (n-p);
    theseTurnBouts = p(turnlen<=(elimboutlen*fps));
    theseTurnLen = turnlen(turnlen<=(elimboutlen*fps));
    for sbind = 1:length(theseTurnLen)
        emt(theseTurnBouts(sbind)+1:theseTurnBouts(sbind)+theseTurnLen(sbind),colNumTurn) = 0;
    end
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colNumTurn)>0));
    if ~isempty(p) && ~isempty(n)
        for tsi = 1:length(n)
            turnInd(sind+p(tsi)-1:sind+n(tsi)-1) = tsi;
            turnDur(sind+p(tsi)-1:sind+n(tsi)-1) = (n(tsi)-p(tsi))/fps;
        end
        nturn(sind:eind) = length(n);
        turnTotDur(sind:eind) = sum(n-p)/fps;
        turnFrac(sind:eind) = sum(n-p)/length(sind:eind);
        
    end
    
    
end

