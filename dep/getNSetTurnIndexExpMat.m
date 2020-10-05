function S = getNSetTurnIndexExpMat(S,angleVelLimit,smoothLen,elimboutlen)
%getNSetTurnIndexExpMat
% S = getNSetTurnIndexExpMat(S,elimboutlen)
% Calculates the indexes for turn bouts and returns S
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
        angleVelLimit = 100;      % mm/sec
end

% get set and fic column and col
S = getSetNfixColumnExpmat(S);

% if stop_on does not exits create and append to expmat
if ~isfield(S.col,'turns_on')
    S = createNAppendColumn2Expmat(S,'turns_on');
end


trackindex = unique(S.expmat(:,1));
turnInd = zeros(size(S.expmat(:,1)));

% smooth the angular speed values
S.expmat = smoothExpMatColumn(S.expmat,S.col.dtheta,smoothLen,'time',S.col.fps);

for tracknum = 1:length(trackindex)
    sind = find(S.expmat(:,1)==trackindex(tracknum),1,'first');
    eind = find(S.expmat(:,1)==trackindex(tracknum),1,'last');
    emt = S.expmat(sind:eind,:);
    expind = S.expmat(sind,2);
    fps = mode(S.expmat(S.expmat(:,2)==expind,S.col.fps));
    % set stops indices
    emt(:,S.col.turns_on) = abs(emt(:,S.col.dtheta))>angleVelLimit;      % mm/sec
    
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.turns_on)>0));
    % eliminate single point noTurns
    if isempty(p) || isempty(n)
        continue
    end
    noTurnlen = (p(2:end)-n(1:end-1));
    thesenoTurnBouts = n(noTurnlen<=(elimboutlen*fps));
    thesenoTurnLen = noTurnlen(noTurnlen<=(elimboutlen*fps));
    for wbind = 1:length(thesenoTurnLen)
        emt(thesenoTurnBouts(wbind)+1:thesenoTurnBouts(wbind)+thesenoTurnLen(wbind),S.col.turns_on) = 1;
    end
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.turns_on)>0));
    % eliminate single point turns
    turnlen = (n-p);
    theseTurnBouts = p(turnlen<=(elimboutlen*fps));
    theseTurnLen = turnlen(turnlen<=(elimboutlen*fps));
    for sbind = 1:length(theseTurnLen)
        emt(theseTurnBouts(sbind)+1:theseTurnBouts(sbind)+theseTurnLen(sbind),S.col.turns_on) = 0;
    end
    % find turn onset and offsets
    [p,n] = getOnOffPoints(diff(emt(:,S.col.turns_on)>0));
    if ~isempty(p) && ~isempty(n)
        for tsi = 1:length(n)
            turnInd(sind+p(tsi)-1:sind+n(tsi)-1) = tsi;
        end
        
    end
    
    
end

% append the turn indexes
S.expmat(:,S.col.turns_on) = turnInd;