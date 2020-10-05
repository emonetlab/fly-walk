% getAllObjectsInFrame.m
% return a structure that contains the properties of the region props
% defined in RP_args. By default BoundingBox, Image, and Area
% 
function r = getAllObjectsInFrame(f,RP_args)

if nargin==1
    RP_args = {'BoundingBox','Image','Area'};
end



raw_image = f.current_raw_frame;
raw_image(raw_image<f.fly_body_threshold) = 0;
L = logical(raw_image);
r = regionprops(L,RP_args);

% remove very small objects as they might be noise
r([r.Area]<f.min_fly_area) = [];