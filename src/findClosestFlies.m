function ObjectsNDistance = findClosestFlies(f,this_fly,n_closest)
%findClosestFliess
% finds the closest flies in the previous frame to this_fly whose 
% distances are less than close_fly_distance. Uses tracking info

% which objects were registered in previous frame
flies_ok_previous_frame = find(~isnan(f.tracking_info.x(:,f.current_frame-1)));

% remove the objects itself
flies_ok_previous_frame(flies_ok_previous_frame==this_fly) = [];

previous_positions_x = f.tracking_info.x(flies_ok_previous_frame,f.current_frame-1);
previous_positions_y = f.tracking_info.y(flies_ok_previous_frame,f.current_frame-1);

fly_pos_x = f.tracking_info.x(this_fly,f.current_frame-1);
fly_pos_y = f.tracking_info.y(this_fly,f.current_frame-1);

% estimate the distance vector
dist_vec = sqrt((previous_positions_x-fly_pos_x).^2+(previous_positions_y-fly_pos_y).^2);

% which ones fall in the criteria
ObjectsNDistance = [flies_ok_previous_frame,dist_vec];

% sort in ascending order
ObjectsNDistance = sortrows(ObjectsNDistance,2);

% how many do you want
ObjectsNDistance = ObjectsNDistance(1:n_closest,:);
