function jumping_split_objects = findJumpingSplitObjects(f,split_objects,resolve_these)
% figures out if the split objects have moved more than jumping distance.
% This is useful when splitting does not split correctlt
%



% resolve these flies
resolve_these = abs(resolve_these);
%
jumping_split_objects = resolve_these;

% first build a distance matrix for all flies to all objects
D = Inf(length(resolve_these),length(split_objects));
for i = 1:length(resolve_these)
	% find the distance from this fly to all objects
	this_fly = resolve_these(i);
	last_known_position = [f.tracking_info.x(this_fly,f.current_frame) f.tracking_info.y(this_fly,f.current_frame)]'; % this should be the same as in the last frame, as positions should be inherited in mapObjectsOntoFlies2
	centroid_locs = reshape([split_objects.Centroid],2,length(split_objects));

	D(i,:) = sqrt((centroid_locs(1,:) - last_known_position(1)).^2 + (centroid_locs(2,:) - last_known_position(2)).^2);
end

% assign objects to flies prioritizing best matches first 
go_on = true;
while go_on
	[best_match_dist,this_fly_idx,this_object]= matrixMin(D);
    if best_match_dist<=f.jump_length_split
        jumping_split_objects(jumping_split_objects==resolve_these(this_fly_idx)) = [];
    end
    % blank out the row and column in the distance matrix to indicate a match
    D(:,this_object) = Inf;
    D(this_fly_idx,:) = Inf;
	
	if isinf(min(D(:)))
		go_on = false;
	end
end