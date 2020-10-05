function ObjectsNDistance = findClosestObjects(f,this_object,n_closest)
%findClosestObjects
% finds the closest objects in the previous frame to this_object whose 
% distances are less than close_fly_distance.

% which objects were registered in previous frame
objects_ok_previous_frame = find(~isnan(f.tracking_info.x(:,f.current_frame-1)));

% remove the objects itself
objects_ok_previous_frame(objects_ok_previous_frame==this_object) = [];

previous_positions_x = f.tracking_info.x(objects_ok_previous_frame,f.current_frame-1);
previous_positions_y = f.tracking_info.y(objects_ok_previous_frame,f.current_frame-1);

obj_num = f.current_object_status==this_object;
obj_pos_x = f.current_objects(obj_num).Centroid(1);
obj_pos_y = f.current_objects(obj_num).Centroid(2);

% estimate the distance vector
dist_vec = sqrt((previous_positions_x-obj_pos_x).^2+(previous_positions_y-obj_pos_y).^2);

% which ones fall in the criteria
ObjectsNDistance = [objects_ok_previous_frame,dist_vec];

% sort in ascending order
ObjectsNDistance = sortrows(ObjectsNDistance,2);

% how many do you want
ObjectsNDistance = ObjectsNDistance(1:n_closest,:);
