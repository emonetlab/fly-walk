function xy = boundbyPxls(xy,PixelList)
%boundbyPxls sets the xy position bounded by pixel list
% if the point is out of the box that is set to the closest pxl on the
% object

% distance matrix
D = pdist2(PixelList,xy);
% closest pixel
xy_closest = PixelList((D==min(D)),:);

criteria = [xy(1)>max(PixelList(:,1)),xy(1)<min(PixelList(:,1)),xy(2)>max(PixelList(:,2)),xy(2)<min(PixelList(:,2))];

if any(criteria)
    xy = xy_closest;
end
