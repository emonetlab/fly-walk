function stemp = getStopTurnColumns(stemp)
% fixes the col structure
% allocates space for new variables
% get set and fix column and col
stemp = getSetNfixColumnExpmat(stemp);

% make ure the following exits
checkFields ={'fps','t','x','y','sx','sy','speed','fileindex','stops_on','turns_on'};
for i = 1:numel(checkFields)
    assert(any(strcmp(checkFields{i},stemp.column)),['"',checkFields{i}, '" does not exist in column definition'])
end

% find or create and append the following
addFields ={'tott','stopind','walkind','nstop','nwalk','stopFrac',...
    'walkFrac','stopDur','walkDur','stopTotDur','walkTotDur',...
    'turnind', 'nturn', 'turnFrac', 'turnDur', 'turnTotDur',...
    'ArrivedSource', 'ArrivedSourcePoint', 'time2Source',...
    'initDistSource', 'initXPos'};

for i = 1:numel(addFields)
    stemp = createNAppendColumn2Expmat(stemp,addFields{i});
end

stemp.expmat(:,stemp.col.tott) = totElapTimeExpMat(stemp.expmat,stemp.col.t);
[stopInd,walkInd,nstop,nwalk,stopFrac,walkFrac,stopDur,walkDur,stopTotDur,walkTotDur] = getStopWalkExpMat(stemp.expmat,stemp.col.stops_on,stemp.col.fps);
[turnInd,nturn,turnFrac,turnDur,turnTotDur] = getTurnExpMat(stemp.expmat,stemp.col.turns_on,stemp.col.fps);
stemp.expmat(:,stemp.col.stopind) = stopInd;
stemp.expmat(:,stemp.col.walkind) = walkInd;
stemp.expmat(:,stemp.col.nstop) = nstop;
stemp.expmat(:,stemp.col.nwalk) = nwalk;
stemp.expmat(:,stemp.col.stopFrac) = stopFrac;
stemp.expmat(:,stemp.col.walkFrac) = walkFrac;
stemp.expmat(:,stemp.col.stopDur) = stopDur;
stemp.expmat(:,stemp.col.walkDur) = walkDur;
stemp.expmat(:,stemp.col.stopTotDur) = stopTotDur;
stemp.expmat(:,stemp.col.walkTotDur) = walkTotDur;
stemp.expmat(:,stemp.col.turnind) = turnInd;
stemp.expmat(:,stemp.col.nturn) = nturn;
stemp.expmat(:,stemp.col.turnFrac) = turnFrac;
stemp.expmat(:,stemp.col.turnDur) = turnDur;
stemp.expmat(:,stemp.col.turnTotDur) = turnTotDur;
end