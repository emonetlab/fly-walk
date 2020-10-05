function f = setOrientations2EllipsoidValues(f)
% sets the orientations in the tracking info to regionprops generated
% ellipsoid diections

% reconstruct current objects
if isempty(f.current_objects)
    f = reConstructCurrentObjetcs(f);
end

for i = 1:numel(f.current_objects)
    f.tracking_info.orientation(f.current_object_status(i),f.current_frame) = mod(-f.current_objects(i).Orientation,360);
end