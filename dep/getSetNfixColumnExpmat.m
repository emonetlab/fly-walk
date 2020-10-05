function S = getSetNfixColumnExpmat(S)
%getSetNfixColumnExpmat
% S = getSetNfixColumnExpmat(S)
% get col and correct fields
% fix spd column
% look for column or header
if ~isfield(S,'column')
    if ~isfield(S,'headers')
        error('Input must have either column or headers')
    else
        S.column = S.headers;
    end
end

% add fields below as needed
Field2Search = {'spd','spd_smooth', 'trjn', 'exp_ind', 'trial_ind', 'trj_ind'};
Field4Replacement = {'speed','speed_smooth', 'trjNum', 'vialNum', 'trialNum', 'trjNumVideo'};

for i = numel(Field2Search)
    S.column(strcmp(S.column,Field2Search{i})) = Field4Replacement(i);
end
if isfield(S,'col')
    for i = numel(Field2Search)
        if isfield(S.col,Field2Search{i})
            S.col.(Field4Replacement{i}) = S.col.(Field2Search{i});
            S.col = rmfield(S.col,Field2Search{i});
        end
    end
end

% if the length of column same as expmat then delete col and regenerate
if numel(S.column)==size(S.expmat,2)
    try
        S = rmfield(S,'col');
    catch
    end
end

% make sure that column has same size as expmat
assert(numel(S.column)==size(S.expmat,2),'Column size does not match expmat size')

% remove any empty columns
colind = 1;
for i = 1:numel(S.column)
    if strcmp(S.column{colind}(1),'e')
        fldnm = S.column{colind};
        if (length(fldnm)>5)&&strcmp(fldnm(1:5),'empty')
            S.column(colind) = [];
            S.expmat(:,colind) = [];
        else
            colind = colind + 1;
        end
    else
        colind = colind + 1;
    end
end
% it can be simply empty
colind = 1;
for i = 1:numel(S.column)
    if isempty(S.column{colind})
        S.column(colind) = [];
        S.expmat(:,colind) = [];
    else
        colind = colind + 1;
    end
end


% get col if does not exist
if ~isfield(S,'col')
    for i = 1:numel(S.column)
        match = 0;
        for j = 1:numel(Field2Search)
            if strcmp(S.column{i},Field2Search{j})
                S.col.(Field4Replacement{j}) = i;
                match = 1;
                continue
            end
        end
        if ~match
            S.col.(strtrim(S.column{i})) = i;
        end
    end
else % if created fill the missing columns
    for i = 1:numel(S.column)
        if ~isfield(S.col,S.column{i})
            match = 0;
            for j = 1:numel(Field2Search)
                if strcmp(S.column{i},Field2Search{j})
                    S.col.(Field4Replacement{j}) = i;
                    match = 1;
                    continue
                end
            end
            if ~match
                S.col.(strtrim(S.column{i})) = i;
            end
        end
    end
end


% put all fileds in the col in to the columnlist
scolFields = fieldnames(S.col)';
allColumnFields = S.column;
for i = 1:numel(scolFields)
    if ~any(strcmp(scolFields(i),allColumnFields))
        S.column(S.col.(scolFields{i})) = scolFields(i);
    end
end

assert(numel(unique(scolFields)) == numel(scolFields),'col has double copies')