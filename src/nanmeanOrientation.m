function meanTheta = nanmeanOrientation(ThetaVec,dim)
%meanOrientation
% meanTheta = meanOrientation(ThetaVec)
% take the given angle list creates units vectors out of them, sums all
% the unit vectors and recalculates the final orientation of the sum
% vector which is the meanTheta. If ThetaVec is a matrix returns mean of
% each column, or call it with dim
%
% input and output angles are in degrees
%
if nargin==1
    dim = 1;
end
if ~isvector(ThetaVec) && ismatrix(ThetaVec)
    if dim==1
        meanTheta = zeros(1,size(ThetaVec,2));
        for i = 1:size(ThetaVec,2)
            meanTheta(i) = nanmeanOrientation(ThetaVec(:,i));
        end
    elseif dim==2
        meanTheta = zeros(size(ThetaVec,1),1);
        for i = 1:size(ThetaVec,1)
            meanTheta(i) = nanmeanOrientation(ThetaVec(i,:));
        end
    else
        error('invalid dim')
    end
else
    ThetaVec = ThetaVec/180*pi;
    ThetaVec(isnan(ThetaVec)) = [];
    if isempty(ThetaVec)
        meanTheta = nan;
    else
        [x,y]=pol2cart(ThetaVec,ones(size(ThetaVec)));
        % add up all the vectors
        x = sum(x);
        y = sum(y);
        
        meanTheta = cart2pol(x,y);
        
        % convert to degrees
        meanTheta = meanTheta/pi*180;
    end
end
