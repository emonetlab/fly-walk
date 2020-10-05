function [p,n] = getOnOffPoints(binary_vector,dim)
%getOnOffPoints
% [p,n] = getOnOffPoints(binary_differentiated_vector)
% returns the onset (p:0>1) and offset (n:0>-1) points
% input is differentiated binary vector
% If a matrix is given then row vectors are assumed, i.e. dim = 2
%
if nargin ==1
    dim = 2; % assume row vector
end
if isvector(binary_vector)

% positive jumps
p = find(binary_vector>0);

% negative jumps
n = find(binary_vector<0);

% remove extra points
if (~isempty(n))&&(~isempty(p))
    
    
    % is there only one point and they are overlapping the borders
    if length(p) == 1 && length(n) == 1 && p>n
        p(2) = p;
        p(1) = 1;
        n(2) = length(binary_vector)+1;
    end
    
    % may be the last sequence ends at the border
    if (length(n)==(length(p)-1))&&(p(end)>n(length(p)-1))
        if iscolumn(p)
            n(length(p),1) = length(binary_vector)+1;
        else
            n(length(p)) = length(binary_vector)+1;
        end
    end
%     % may be there is one missing point
%     if length(n)==(length(p)-1)
%         n(1) = length(binary_vector);
%     end
    
    if length(p)==(length(n)-1)
        p(2:end+1) = p;
        p(1) = 1;
        % get the correct vector orientation
        if iscolumn(n)
            if isrow(p)
                p = p';
            end
        else
            if iscolumn(p)
                p = p';
            end
        end
        
    end
    
    
    if (n(1)<p(1))
        if length(n)==length(p)
            p(2:end+1) = p;
            p(1) = 1;
            if (n(end)<p(end))
                n(end+1) = length(binary_vector)+1;
            end
        else
            n(1) = [];
        end
    end
    
    if (n(end)<p(end))
        p(end) = [];
    end
end

if isempty(n)&&(length(p)==1)
    n = length(binary_vector)+1;
end

if isempty(p)&&(length(n)==1)
    p = 1;
end



elseif ismatrix(binary_vector)
    assert(length(size(binary_vector))==2,'did not code for matrixes with dimensions more than 2')
    if dim == 2
        p = cell(size(binary_vector,1),1);
        n = cell(size(binary_vector,1),1);
        for i = 1:size(binary_vector,1)
            [ptemp,ntemp] = getOnOffPoints(binary_vector(i,:));
            p(i) = {ptemp};
            n(i) = {ntemp};
        end
    elseif dim == 1
        p = cell(1,size(binary_vector,2));
        n = cell(1,size(binary_vector,2));
        for i = 1:size(binary_vector,2)
            [ptemp,ntemp] = getOnOffPoints(binary_vector(:,i));
            p(i) = {ptemp};
            n(i) = {ntemp};
        end
    else
        error('invalid dim')
    end
    
end

