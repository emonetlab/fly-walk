function S = getNSetStopIndexExpMat(S,speedLimit,smoothLen,elimboutlen)
%getNSetStopIndexExpMat
% S = getNSetStopIndexExpMat(S,elimboutlen)
% Calculates the indexes for stops bouts and returns S
% Calculated stops are returned in expmat in S with the column 'stops_on'.
% If that column already exits then the values are replaced, if not a new
% column will be created 
%

switch nargin
    case 3
        elimboutlen = .1;    % sec
    case 2
        elimboutlen = .1;    % sec
        smoothLen = 0.3;     %sec
    case 1
        elimboutlen = .1;    % sec
        smoothLen = 0.3;     % sec
        speedLimit = 2;      % mm/sec
end

% get set and fix column and col
S = getSetNfixColumnExpmat(S);

% if stop_on does not exits create and append to expmat
if ~isfield(S.col,'stops_on')
    S = createNAppendColumn2Expmat(S,'stops_on');
end


trackindex = unique(S.expmat(:,1));
stopInd = zeros(size(S.expmat(:,1)));

for tracknum = 1:length(trackindex)
    sind = find(S.expmat(:,1)==trackindex(tracknum),1,'first');
    eind = find(S.expmat(:,1)==trackindex(tracknum),1,'last');
    emt = S.expmat(sind:eind,:);
    expind = S.expmat(sind,2);
    fps = mode(S.expmat(S.expmat(:,2)==expind,S.col.fps));
    % set stops indices
    emt(:,S.col.stops_on) = smooth(emt(:,S.col.speed),round(smoothLen*fps))<speedLimit;      % mm/sec
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.stops_on)>0));
    % eliminate single point walks
    if isempty(p)||isempty(n)
        continue
    end
    walklen = (p(2:end)-n(1:end-1));
    theseWalkBouts = n(walklen<=(elimboutlen*fps));
    theseWalkLen = walklen(walklen<=(elimboutlen*fps));
    for wbind = 1:length(theseWalkLen)
        emt(theseWalkBouts(wbind)+1:theseWalkBouts(wbind)+theseWalkLen(wbind),S.col.stops_on) = 1;
    end
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.stops_on)>0));
    % eliminate single point stops
    stoplen = (n-p);
    theseStopBouts = p(stoplen<=(elimboutlen*fps));
    theseStopLen = stoplen(stoplen<=(elimboutlen*fps));
    for sbind = 1:length(theseStopLen)
        emt(theseStopBouts(sbind)+1:theseStopBouts(sbind)+theseStopLen(sbind),S.col.stops_on) = 0;
    end
    % find stop onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.stops_on)>0));
    if ~isempty(p) && ~isempty(n)
        for tsi = 1:length(n)
            stopInd(sind+p(tsi)-1:sind+n(tsi)-1) = tsi;
        end
    end
end

% append the stop indexes
S.expmat(:,S.col.stops_on) = stopInd;
