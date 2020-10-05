function smoothTheta = smoothOrientation(Theta,n)
% Smooths given orientation vector Theta (degrees) by vector averaging n
% points aorund a given point. If even n is given it increments it by one;
% take the given angle list creates units vectors out of them, sums all
% the unit vectors and recalculates the final orientation of the sum
% vector
%
% input and output angles are in degrees
%
% by Mahmut Demir 10.22.2017
%

if n<=1
    smoothTheta = Theta;
    return
end

if rem(n,2) ==0 % increase n by one if it is even.
    n = n+1;
end

smoothTheta = nan(length(Theta),1);  % initiate smoothed data
ldata = length(Theta);                   % get length of the data

% make Theta a column vector
Theta = Theta(:);

for i = 1:ldata
    if i<(n+1)/2
        datat = [Theta(1:1+(n-1)/2-i);Theta(1:i+(n-1)/2)];
        % remove nans
        datat(isnan(datat)) = [];
        if isempty(datat)
            continue
        else
            smoothTheta(i) = meanOrientation(datat);
        end
    elseif i>ldata-(n-1)/2
        datat = [Theta(i-(n-1)/2:ldata);Theta((2*ldata)-i-((n-1)/2)+1:ldata)];
        % remove nans
        datat(isnan(datat)) = [];
        if isempty(datat)
            continue
        else
            smoothTheta(i) = meanOrientation(datat);
        end
    else
        datat = Theta(i-(n-1)/2:i+(n-1)/2);
        % remove nans
        datat(isnan(datat)) = [];
        if isempty(datat)
            continue
        else
            smoothTheta(i) = meanOrientation(datat);
        end
    end
end

