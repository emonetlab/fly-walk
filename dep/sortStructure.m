function S = sortStructure(S,fieldname)
% sorts the filed rows according to the fieldname

% save the structure to a temporary variavle
Stemp = S;

% get filed values
val = [S.(fieldname)];

% sort field values
[~,ind]=sort(val);

% sort the structure
for i = 1:numel(S)
    S(i) = Stemp(ind(i));
end

    