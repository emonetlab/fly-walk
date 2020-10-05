%% assignObjectsToTheseFlies
% this is a sub-function that is called by mapObjectsOntoFlies
% this sub-function assigns objects onto flies
% usage:
% f = assignObjectsToTheseFlies(f,these_flies)
% where
% 
% f is a flyWalk object
% and these_flies is a vector containing the IDs of flies in [1...N]

function f = assignObjectsToTheseFlies(f,these_flies)

if isempty(these_flies)
	return
end

if isempty(f.current_objects)
    return
end

% unpack data
tracking_info = f.tracking_info;
current_frame = f.current_frame;
current_object_status = f.current_object_status;
reflection_status = f.reflection_status;
reflection_meas = f.reflection_meas;
r = f.current_objects;

% first build a distance matrix for all flies to all objects
D = Inf(length(these_flies),length(r));
for i = 1:length(these_flies)
	% find the distance from this fly to all objects
	this_fly = these_flies(i);
	last_known_position = [tracking_info.x(this_fly,current_frame) tracking_info.y(this_fly,current_frame)]'; % this should be the same as in the last frame, as positions should be inherited in mapObjectsOntoFlies2

	centroid_locs = reshape([r.Centroid],2,length(r));
	centroid_locs(:,current_object_status>0) = Inf;

	D(i,:) = sqrt((centroid_locs(1,:) - last_known_position(1)).^2 + (centroid_locs(2,:) - last_known_position(2)).^2);
end

% assign objects to flies prioritizing best matches first 
go_on = true;
while go_on
	[best_match_dist,this_fly_idx,this_object]= matrixMin(D);
	if best_match_dist < f.maximum_distance_to_link_trajectories
%         
%         if these_flies(this_fly_idx)==58
%             keyboard
%         end
        % if that is a lost fly in the periphery ignore
        [to_this_fly,is_in_the_periphery] = isAssignedtoLostFly(f,r(this_object).Centroid);
        to_this_existing_fly = isAssignedtoWhichFly(f,r(this_object).Centroid);
        
        % this method is not good. check the output and see how it works
        try

            if ~isempty(to_this_fly)&&~wasThisFlyClose(f,these_flies(this_fly_idx),r(this_object).Centroid)
                if f.ft_debug
                    if is_in_the_periphery
                        disp(['fly: ',num2str(these_flies(this_fly_idx)),' is matched to the lost fly: ', ...
                        num2str(to_this_fly),' at the periphery. Ignoring...'])
                    else
                        disp(['fly: ',num2str(these_flies(this_fly_idx)),' is matched to the lost fly: ', ...
                        num2str(to_this_fly),'. Ignoring...'])
                    end
                end

                % object is lost, may be colliding or overlapping
                % fly is considered missing as the new object is too far away from last known location
                [tracking_info] = markFlyMissing(tracking_info,these_flies(this_fly_idx),current_frame);
                % blank out the row and column in the distance matrix to indicate a match
                D(:,this_object) = Inf;
                D(this_fly_idx,:) = Inf;
                
            elseif ~isempty(to_this_fly)&&(any(current_object_status==these_flies(this_fly_idx)))
                  % assign this object to this fly
                disp(['fly: ',num2str(these_flies(this_fly_idx)),' is already assigned. Ignoring...'])

                D(this_fly_idx,:) = Inf;

            elseif ~isempty(wasThisFlyInteracting(f,these_flies(this_fly_idx)))&&~wasThisFlyClose(f,these_flies(this_fly_idx),r(this_object).Centroid)&&...
                    ~isempty(to_this_existing_fly)&&~(to_this_existing_fly==these_flies(this_fly_idx))&&...
                    ~(any(wasThisFlyInteracting(f,these_flies(this_fly_idx))==to_this_existing_fly))
                if f.ft_debug
                    disp(['Interacting fly: ',num2str(these_flies(this_fly_idx)),' is matched to the lost fly: ', ...
                        num2str(to_this_existing_fly),' at the periphery. Ignoring...'])
                end

                % object is lost, may be colliding or overlapping
                % fly is considered missing as the new object is too far away from last known location
                [tracking_info] = markFlyMissing(tracking_info,these_flies(this_fly_idx),current_frame);
                % blank out the row and column in the distance matrix to indicate a match
                D(:,this_object) = Inf;
                D(this_fly_idx,:) = Inf;

            elseif isIntheCollignoreZone(f,r(this_object).Centroid)&&(best_match_dist>f.jump_length_split)&&~isempty(wasThisFlyInteracting(f,these_flies(this_fly_idx)))
                % fly is linked to an object that appeared in the collision
                % ignore zone and link distance is larger than jump distance
                if f.ft_debug
                    disp(['Interacting fly: ',num2str(these_flies(this_fly_idx)),' is matched to an onject in the CollIgnoreZone. Ignoring...'])
                end

                % object is lost, may be colliding or overlapping
                % fly is considered missing as the new object is too far away from last known location
                [tracking_info] = markFlyMissing(tracking_info,these_flies(this_fly_idx),current_frame);
                % blank out the row and column in the distance matrix to indicate a match
                D(:,this_object) = Inf;
                D(this_fly_idx,:) = Inf;

            elseif getInteractionTime(f,these_flies(this_fly_idx))>=f.max_interaction_time
                % fly got lost in the interaction
                if f.ft_debug
                    disp(['Fly: ',mat2str(these_flies(this_fly_idx)),' has been interacting for ',num2str(f.max_interaction_time),' sec. Dropping...'])
                end
                tracking_info.error_code(these_flies(this_fly_idx),f.current_frame) = 4;
                tracking_info.fly_status(these_flies(this_fly_idx),f.current_frame) = 4;
                tracking_info.x(these_flies(this_fly_idx),f.current_frame) = NaN;
                tracking_info.y(these_flies(this_fly_idx),f.current_frame) = NaN;
                tracking_info.area(these_flies(this_fly_idx),f.current_frame) = NaN;
                

                D(:,this_object) = Inf;
                D(this_fly_idx,:) = Inf;

            else
                % assign this object to this fly
                current_object_status(this_object) = these_flies(this_fly_idx);

                % now assign the object properties
                closest_obj = r(this_object);
                tracking_info.x(these_flies(this_fly_idx),current_frame) = closest_obj.Centroid(1);
                tracking_info.y(these_flies(this_fly_idx),current_frame) = closest_obj.Centroid(2);
                tracking_info.fly_status(these_flies(this_fly_idx),current_frame) = 1; % assigned and visible
                if ~isempty(closest_obj.Orientation)
                        if isnan(closest_obj.Orientation)
                            tracking_info.orientation(these_flies(this_fly_idx),current_frame) = tracking_info.orientation(these_flies(this_fly_idx),current_frame-1);
                        else
                            tracking_info.orientation(these_flies(this_fly_idx),current_frame) = mod(-closest_obj.Orientation,360);
                        end
                    else
                        tracking_info.orientation(these_flies(this_fly_idx),current_frame) = tracking_info.orientation(these_flies(this_fly_idx),current_frame-1);
                end


                fields2look = {'Area','MajorAxisLength','MinorAxisLength','Perimeter','Eccentricity'};
                fields2write = {'area','majax','minax','perimeter','excent'};
                for i = 1:length(fields2look)
                    if ~isempty(closest_obj.(fields2look{i}))
                        if isnan(closest_obj.(fields2look{i}))
                            tracking_info.(fields2write{i})(these_flies(this_fly_idx),current_frame) = tracking_info.(fields2write{i})(these_flies(this_fly_idx),current_frame-1);
                        else
                            tracking_info.(fields2write{i})(these_flies(this_fly_idx),current_frame) = closest_obj.(fields2look{i});
                        end
                    else
                        tracking_info.(fields2write{i})(these_flies(this_fly_idx),current_frame) = tracking_info.(fields2write{i})(these_flies(this_fly_idx),current_frame-1);
                    end
                end

        %         tracking_info.majax(these_flies(this_fly_idx),current_frame) = closest_obj.MajorAxisLength; % major axis
        %         tracking_info.minax(these_flies(this_fly_idx),current_frame) = closest_obj.MinorAxisLength; % major axis
                if isfield(closest_obj,'RFluo')
                    if isempty(closest_obj.RFluo)
                        reflection_meas(these_flies(this_fly_idx),current_frame) = ...
                            reflection_meas(these_flies(this_fly_idx),find(reflection_meas(these_flies(this_fly_idx),1:current_frame-1)>0, 1, 'last'));
                    else
                        reflection_meas(these_flies(this_fly_idx),current_frame) = closest_obj.RFluo;
                    end
                    refmt = nonzeros(reflection_meas(these_flies(this_fly_idx),~isnan(reflection_meas(these_flies(this_fly_idx),1:f.current_frame))));
    %                 refmt = nonzeros(reflection_meas(these_flies(this_fly_idx),1:f.current_frame));
                    if length(refmt)>f.ref_check_len
                        refmt = refmt(end-f.ref_check_len:end);
                    end
                    reflection_status(these_flies(this_fly_idx),current_frame) = mean(refmt)>f.ref_thresh;

                else
                    reflection_status(these_flies(this_fly_idx),current_frame) = reflection_status(these_flies(this_fly_idx),current_frame-1);
                end

                % take care of reflections of flies at the periphery
                if (tracking_info.fly_status(these_flies(this_fly_idx),f.current_frame-1)==2)...
                        ||(tracking_info.fly_status(these_flies(this_fly_idx),f.current_frame-1)==0)...
                    ||(tracking_info.fly_status(these_flies(this_fly_idx),f.current_frame-1)==3)
                    f.frames_ref_meas = [f.frames_ref_meas;[f.current_frame+...
                            f.new_obj_ref_meas_buffer,these_flies(this_fly_idx)]];
                end

                % blank out the row and column in the distance matrix to indicate a match
                D(:,this_object) = Inf;
                D(this_fly_idx,:) = Inf;
            end
        catch ME
            disp(ME.message)
            D(:,this_object) = Inf;
            D(this_fly_idx,:) = Inf;
        end
            
            
    else

		% object too far
		% disp('fly too far from object')
		% fly is considered missing as the new object is too far away from last known location
		[tracking_info] = markFlyMissing(tracking_info,these_flies(this_fly_idx),current_frame);
        
        % nmeaasure the distance to the edges
        

        pdistm = FlyDist2Edges(f,these_flies(this_fly_idx));
        if isnan(min(pdistm))
            keyboard
        end
            
        % if too close to the wall assign as it has left the arena
        if any(pdistm<=f.dist_fly_edge_leave)
            tracking_info.fly_status(these_flies(this_fly_idx),current_frame) = 3; % assigned and away
        end


		% blank out the row and column in the distance matrix to indicate a match
		D(:,this_object) = Inf;
		D(this_fly_idx,:) = Inf;

	end

	if isinf(min(D(:)))
		go_on = false;
	end
end

% repack data for export
f.tracking_info = tracking_info;
f.current_object_status = current_object_status;
f.reflection_meas = reflection_meas;
f.reflection_status = reflection_status;