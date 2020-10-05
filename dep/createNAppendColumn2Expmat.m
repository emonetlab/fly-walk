function S = createNAppendColumn2Expmat(S,colName)
%createNAppendColumn2Expmat
% S = createNAppendColumn2Expmat(S,colName)
% if the requested column does not exits appends it to the column and col
% as a new field. Column number is set as the next columnat the end of the
% expmat
%

if isfield(S.col,colName) || any(strcmp(S.column,colName))
%     disp(['"',colName,'"',': Requested column exits.'])
    S = getSetNfixColumnExpmat(S);
    return
end

% set the column number
colNum = numel(S.column)+1; 
S.column(colNum) = {colName};
S.expmat(:,colNum) = nan;
S.col.(colName) = colNum;