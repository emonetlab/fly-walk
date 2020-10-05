function f = getPerimeterNEccent(f)
% collects the perimeter and eccentiricity of the detected objects and
% assigns to the closest tracked flies

% Grooming detection
f.tracking_info.perimeter = zeros(size(f.tracking_info.signal));
f.tracking_info.excent = zeros(size(f.tracking_info.signal));

f.track_movie=0;

f.current_frame=1;
f.operateOnFrame;

for thisframe = 1:f.nframes
    f.previous_frame = f.current_frame;
    f.current_frame = thisframe;
    f.operateOnFrame;
    S=getAllObjectsInFrame(f,[f.regionprops_args,{'Perimeter','Eccentricity'}]);
    disp(['frame:',num2str(f.current_frame),' ',num2str(numel(S)),' flies found'])
    
    if isempty(S)
        continue
    end
    
    theseflies = find(f.tracking_info.fly_status(:,thisframe)==1);

    % Getting the pixels position of the actual fly in the frame:
    pos=[S.Centroid];
    pos = reshape(pos,2,length(pos)/2);
    
    for itergg = 1:length(theseflies)
        
        this_fly = theseflies(itergg);
        
        fly_pos_x = f.tracking_info.x(this_fly,f.current_frame);
        fly_pos_y = f.tracking_info.y(this_fly,f.current_frame);
        
        % estimate the distance vector
        dist_vec = sqrt((pos(1,:)-fly_pos_x).^2+(pos(2,:)-fly_pos_y).^2);
        
        % which ones fall in the criteria
        ObjectsNDistance = [(1:numel(S))',dist_vec'];
        
        % sort in ascending order
        ObjectsNDistance = sortrows(ObjectsNDistance,2);
        
        this_object = ObjectsNDistance(1);
        f.tracking_info.perimeter(this_fly,f.current_frame) = S(this_object).Perimeter;
        f.tracking_info.excent(this_fly,f.current_frame) = S(this_object).Eccentricity;

    end
end




