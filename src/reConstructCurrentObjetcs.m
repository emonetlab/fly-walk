function  f = reConstructCurrentObjetcs(f,framenum)
% finds all objects in the arana by regionprops and assigns the current
% object status by finding the closes flies
if nargin==1
    framenum =  f.current_frame;
end

f = findAllObjectsInFrame(f);

% who are the current active flies
theseflies = find(f.tracking_info.fly_status(:,framenum)==1);

if length(f.current_object_status)<length(theseflies)
    f.current_object_status =  zeros(size(theseflies));
end

% Getting the pixels position of the actual fly in the frame:
pos=[f.current_objects.Centroid];
pos = reshape(pos,2,length(pos)/2);

% account for interaction resolutions
add_elem_num  = 0;

for itergg = 1:length(theseflies)

    this_fly = theseflies(itergg);

    fly_pos_x = f.tracking_info.x(this_fly,framenum);
    fly_pos_y = f.tracking_info.y(this_fly,framenum);

    % estimate the distance vector
    dist_vec = sqrt((pos(1,:)-fly_pos_x).^2+(pos(2,:)-fly_pos_y).^2);

    % which ones fall in the criteria
    ObjectsNDistance = [(1:(numel(f.current_objects)-add_elem_num))',dist_vec'];

    % sort in ascending order
    ObjectsNDistance = sortrows(ObjectsNDistance,2);
    if f.current_object_status(ObjectsNDistance(1))==0 
        f.current_object_status(ObjectsNDistance(1)) = this_fly ;
    else
        f.current_objects = [f.current_objects;f.current_objects(end)];
        f.current_object_status(numel(f.current_objects)) = this_fly ;
        add_elem_num = add_elem_num + 1;
    end
end

% delete the unaasigned objects
f.current_objects(f.current_object_status==0) = [];
f.current_object_status(f.current_object_status==0) = [];