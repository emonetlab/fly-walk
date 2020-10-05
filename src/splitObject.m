% splits a object
% using k-means
function [split_objects] = splitObject(clean_image,r0,how_many_parts)

if nargin<3
    how_many_parts = 2;
end

ff = bwlabel(cutImage(clean_image',r0.Centroid,50)');
dominant_label = mode(nonzeros(ff(:)));
ff(ff~=dominant_label) = 0;
ff(ff~=0) = 1;

% use k-means to split them
temp = regionprops(ff,'PixelList');
[idx,C] = kmeans(gather(temp.PixelList),how_many_parts);
split_objects(how_many_parts) = r0;

for part = 1:how_many_parts
    % inherit everything
    split_objects(part).Centroid(1) =  C(part,1);
    split_objects(part).Centroid(2) =  C(part,2);
    split_objects(part).Area = sum(idx==part);

    % also inherit the orientations 
    split_objects(part).Orientation = r0.Orientation;

    % split the Area evenly between them
    split_objects(part).Area = r0.Area/how_many_parts;
    
    % get approximate major length
    split_objects(part).MajorAxisLength= split_objects(part).Area/7;
    
    % get approximate minor length
    split_objects(part).MinorAxisLength= split_objects(part).Area/14;


end

for j = 1:length(split_objects)
    split_objects(j).Centroid(1) = split_objects(j).Centroid(1) + r0.Centroid(1) - 50 ;
    split_objects(j).Centroid(2) = split_objects(j).Centroid(2) + r0.Centroid(2) - 50;
end