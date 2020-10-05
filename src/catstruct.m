function S = catstruct(S1,S2)
% concatanete structures with different fields

% if any of these two is empty then return the other one
if isempty(S1)&&isempty(S2)
    error('both structures are empty')
elseif isempty(S1)
    S = S2; % return the other
elseif isempty(S2)
    S = S1; % return the other
else
    % get all fieldnames
    if ~isempty(S1)
        fn1 = fieldnames(S1);
    else
        fn1 = [];
    end
    if ~isempty(S2)
        fn2 = fieldnames(S2);
    else
        fn2 = [];
    end
    % get unique field names
    fnu = unique([fn1;fn2],'stable');

    % reset the structures with missing fields
    [c,~]=setdiff(fnu,fn1);
    if ~isempty(c)
        for i = 1:numel(c)
            S1(end).(c{i}) = [];
        end
    end
    [c,~]=setdiff(fnu,fn2);
    if ~isempty(c)
        for i = 1:numel(c)
            S2(end).(c{i}) = [];
        end
    end
    % now concatanate
%     S = [S1;S2];
    if iscolumn(S1)
        if iscolumn(S2)
            S = [S1;S2];
        else
            S = [S1;S2'];
        end
    else
        if isrow(S2)
            S = [S1,S2];
        else
            S = [S1,S2'];
        end
    end
            
end



    



