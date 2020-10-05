function [stopInd,walkInd,nstop,nwalk,stopFrac,walkFrac,stopDur,walkDur,stopTotDur,walkTotDur] = getStopWalkExpMat(em,colnumstop,colnumfps,elimboutlen)
%getStopWalkExpMat
% [stopInd,walkInd,nstop,nwalk,stopDur,walkDur,stopTotDur,walkTotDur] = getStopWalkExpMat(em,colnumstop,colnumfps)
% Calculates the indexes for stops and walk bouts, the durations for these
% bouts, the total durations of the walks and stops as wel as number of
% stops and walks
% default stopcolumn is assumed to be the last column
% default fps column is 20
%

switch nargin
    case 3
        elimboutlen = .1;    % sec
    case 2
        elimboutlen = .1;    % sec
        colnumfps = 20;
    case 1
        elimboutlen = .1;    % sec
        colnumfps = 20;
        colnumstop = size(em,2);
end

trackindex = unique(em(:,1));
stopInd = zeros(size(em(:,1)));
walkInd = zeros(size(em(:,1)));
nstop = zeros(size(em(:,1)));
nwalk = zeros(size(em(:,1)));
stopDur = zeros(size(em(:,1)));
walkDur = zeros(size(em(:,1)));
stopFrac = zeros(size(em(:,1)));
walkFrac = zeros(size(em(:,1)));
stopTotDur = zeros(size(em(:,1)));
walkTotDur = zeros(size(em(:,1)));

for tracknum = 1:length(trackindex)
    sind = find(em(:,1)==trackindex(tracknum),1,'first');
    eind = find(em(:,1)==trackindex(tracknum),1,'last');
    emt = em(sind:eind,:);
    expind = em(sind,2);
    fps = mode(em(em(:,2)==expind,colnumfps));
    
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colnumstop)>0));
    % eliminate single point walks
    if isempty(p)||isempty(n)
        continue
    end
    walklen = (p(2:end)-n(1:end-1));
    theseWalkBouts = n(walklen<=(elimboutlen*fps));
    theseWalkLen = walklen(walklen<=(elimboutlen*fps));
    for wbind = 1:length(theseWalkLen)
        emt(theseWalkBouts(wbind)+1:theseWalkBouts(wbind)+theseWalkLen(wbind),colnumstop) = 1;
    end
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colnumstop)>0));
    % eliminate single point stops
    stoplen = (n-p);
    theseStopBouts = p(stoplen<=(elimboutlen*fps));
    theseStopLen = stoplen(stoplen<=(elimboutlen*fps));
    for sbind = 1:length(theseStopLen)
        emt(theseStopBouts(sbind)+1:theseStopBouts(sbind)+theseStopLen(sbind),colnumstop) = 0;
    end
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,colnumstop)>0));
    if ~isempty(p) && ~isempty(n)
        for tsi = 1:length(n)
            stopInd(sind+p(tsi)-1:sind+n(tsi)-1) = tsi;
            stopDur(sind+p(tsi)-1:sind+n(tsi)-1) = (n(tsi)-p(tsi))/fps;
        end
        nstop(sind:eind) = length(n);
        stopTotDur(sind:eind) = sum(n-p)/fps;
        stopFrac(sind:eind) = sum(n-p)/length(sind:eind);
        
        % get walk onset and offsets
        pw = n(1:end-1)+1;
        nw = p(2:end)-1;
        if p(1)>1
            pw(2:end+1) = pw;
            nw(2:end+1) = nw;
            pw(1) = 1;
            nw(1) = p(1)-1;
        end
        if n(end)<length(sind:eind)
            pw(end+1) = n(end)+1;
            nw(end+1) = length(sind:eind);
        end
        
        if ~isempty(pw) && ~isempty(nw)
            for tsi = 1:length(nw)
                walkInd(sind+pw(tsi)-1:sind+nw(tsi)-1) = tsi;
                walkDur(sind+pw(tsi)-1:sind+nw(tsi)-1) = (nw(tsi)-pw(tsi))/fps;
            end
            nwalk(sind:eind) = length(nw);
            walkTotDur(sind:eind) = sum(nw-pw)/fps;
            walkFrac(sind:eind) = sum(nw-pw)/length(sind:eind);
        end
    end
    
    
end

