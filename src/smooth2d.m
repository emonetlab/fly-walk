function imout = smooth2d(imin,wins,option,nans)

switch nargin
    case 3
        nans = 'ignore';    % ignore nans. 
    case 2
        nans = 'ignore';    % ignore nans.
        option = 'mean';    % get mean filter
    case 1
        nans = 'ignore';    % ignore nans.
        option = 'mean';    % get mean filter
        wins = 0;           % do not smooth
end


% get cropping indexes
imsize = size(imin);
imout = NaN(size(imin));

% go over the image indexes and do the averaging
if strcmp(nans,'ignore')&&strcmp(option,'mean')
    for row = 1:imsize(1)
        for col = 1:imsize(2)
            indmat = getindmat(imsize,[row,col],wins);
            matcrop = imin(indmat(1,1):indmat(2,1),indmat(1,2):indmat(2,2));
            matcrop = matcrop(:);
            matcrop(isnan(matcrop)) = [];
            imout(row,col) = mean(matcrop);
        end
    end
elseif strcmp(nans,'ignore')&&strcmp(option,'median')
    for row = 1:imsize(1)
        for col = 1:imsize(2)
            indmat = getindmat(imsize,[row,col],wins);
            matcrop = imin(indmat(1,1):indmat(2,1),indmat(1,2):indmat(2,2));
            matcrop = matcrop(:);
            matcrop(isnan(matcrop)) = [];
            imout(row,col) = median(matcrop);
        end
    end
elseif strcmp(nans,'zero')&&strcmp(option,'mean')
    for row = 1:imsize(1)
        for col = 1:imsize(2)
            indmat = getindmat(imsize,[row,col],wins);
            matcrop = imin(indmat(1,1):indmat(2,1),indmat(1,2):indmat(2,2));
            matcrop = matcrop(:);
            matcrop(isnan(matcrop)) = 0;
            imout(row,col) = mean(matcrop);
        end
    end
elseif strcmp(nans,'zero')&&strcmp(option,'median')
    for row = 1:imsize(1)
        for col = 1:imsize(2)
            indmat = getindmat(imsize,[row,col],wins);
            matcrop = imin(indmat(1,1):indmat(2,1),indmat(1,2):indmat(2,2));
            matcrop = matcrop(:);
            matcrop(isnan(matcrop)) = [];
            imout(row,col) = median(matcrop);
        end
    end
end
imout(isnan(imin)) = nan;
        
            
