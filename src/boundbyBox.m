function xy = boundbyBox(xy,BoundingBox)
%boundbyBox sets the xy position bounded by boundingbox
% if the point is out of the box that is set to the boundary

if xy(1)>(BoundingBox(1)+BoundingBox(3))
    xy(1) = (BoundingBox(1)+BoundingBox(3));
end
if xy(1)<(BoundingBox(1))
    xy(1) = (BoundingBox(1));
end

if xy(2)>(BoundingBox(2)+BoundingBox(4))
    xy(2) = (BoundingBox(2)+BoundingBox(4));
end
if xy(2)<(BoundingBox(2))
    xy(2) = (BoundingBox(2));
end