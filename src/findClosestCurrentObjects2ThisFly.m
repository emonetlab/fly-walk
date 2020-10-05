function ObjectsNDistance = findClosestCurrentObjects2ThisFly(f,this_fly,n_closest,framenum)
%findClosestCurrentObjects
% finds the closest objects to this_object whose distances are less than
% close_fly_distance.
if nargin==3
    framenum = f.current_frame;
end

% reconstruct the current objects if not available
if isempty(f.current_objects)
    if ~(framenum==f.current_frame)
        f.current_frame = framenum;
        f.operateOnFrame;
    end
    f = reConstructCurrentObjetcs(f,framenum);
end

% which objects were registered in previous frame
current_objects_status = f.current_object_status;
current_objects = f.current_objects;

delete_this = current_objects_status==this_fly;
% remove the objects itself
current_objects_status(delete_this) = [];
current_objects(delete_this) = [];

% may be there is only the missing fly
if isempty(current_objects_status)
    ObjectsNDistance = [];
    return
end
    
if n_closest>numel(current_objects)
    n_closest = numel(current_objects);
end

pos=[current_objects.Centroid];
pos = reshape(pos,2,length(pos)/2);

previous_positions_x = pos(1,:);
previous_positions_y = pos(2,:);

fly_pos_x = f.tracking_info.x(this_fly,framenum);
fly_pos_y = f.tracking_info.y(this_fly,framenum);

% estimate the distance vector
dist_vec = sqrt((previous_positions_x-fly_pos_x).^2+(previous_positions_y-fly_pos_y).^2);

% which ones fall in the criteria
ObjectsNDistance = [current_objects_status,dist_vec'];

% sort in ascending order
ObjectsNDistance = sortrows(ObjectsNDistance,2);

if n_closest>length(ObjectsNDistance)
    n_closest = length(ObjectsNDistance);
end
% how many do you want
ObjectsNDistance = ObjectsNDistance(1:n_closest,:);
