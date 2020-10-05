function ObjectsNDistance = findClosestCurrentObjects(f,this_object,n_closest)
%findClosestCurrentObjects
% finds the closest objects to this_object whose distances are less than
% close_fly_distance.

% which objects were registered in previous frame
current_objects_status = f.current_object_status;
current_objects = f.current_objects;

delete_this = current_objects_status==this_object;
% remove the objects itself
current_objects_status(delete_this) = [];
current_objects(delete_this) = [];

pos=[current_objects.Centroid];
pos = reshape(pos,2,length(pos)/2);

previous_positions_x = pos(1,:);
previous_positions_y = pos(2,:);

obj_num = f.current_object_status==this_object;
obj_pos_x = f.current_objects(obj_num).Centroid(1);
obj_pos_y = f.current_objects(obj_num).Centroid(2);

% estimate the distance vector
dist_vec = sqrt((previous_positions_x-obj_pos_x).^2+(previous_positions_y-obj_pos_y).^2);

% which ones fall in the criteria
ObjectsNDistance = [current_objects_status,dist_vec'];

% sort in ascending order
ObjectsNDistance = sortrows(ObjectsNDistance,2);

% how many do you want
ObjectsNDistance = ObjectsNDistance(1:n_closest,:);
