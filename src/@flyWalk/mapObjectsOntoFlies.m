%% mapObjectsOntoFlies
% maps all identified objects in a frame onto previously known positions of flies
% 

function f = mapObjectsOntoFlies(f)

if f.current_frame == 1
	return
end

% unpack some data 
current_frame = f.current_frame;

% we should already have found the objects in this frame now

% flies OK in the last frame --> missing in this frame
flies_ok_in_last_frame = find(f.tracking_info.fly_status(:,current_frame-1) == 1);
f.tracking_info.fly_status(flies_ok_in_last_frame,current_frame) = 2;

% flies missing in last frame --> still missing in this frame
flies_missing_in_last_frame = find(f.tracking_info.fly_status(:,current_frame-1) == 2);
f.tracking_info.fly_status(flies_missing_in_last_frame,current_frame) = 2;

% flies missing left the arena in last frame --> still gone
flies_gone_in_last_frame = find(f.tracking_info.fly_status(:,current_frame-1) == 3);
f.tracking_info.fly_status(flies_gone_in_last_frame,current_frame) = 3;


% flies lost in the interaction in last frame --> dropped
flies_lost_in_interaction = find(f.tracking_info.fly_status(:,current_frame-1) == 4);
f.tracking_info.fly_status(flies_lost_in_interaction,current_frame) = 4;

% terminated guys are still terminated
flies_terminated = isnan(f.tracking_info.fly_status(:,current_frame-1));
f.tracking_info.fly_status(flies_terminated,current_frame) = NaN;

% fly positions in last frame --> fly positions in this frame, be careful
% about backward running
% all_flies = max([flies_ok_in_last_frame;find(flies_missing_in_last_frame)]);
% all_flies = max([flies_ok_in_last_frame;find(flies_gone_in_last_frame);find(flies_missing_in_last_frame)]);
% only_these_flies = 1:all_flies;
only_these_flies = [flies_ok_in_last_frame;flies_gone_in_last_frame;flies_missing_in_last_frame;flies_lost_in_interaction];
f.tracking_info.x(only_these_flies,current_frame) = f.tracking_info.x(only_these_flies,current_frame-1);
f.tracking_info.y(only_these_flies,current_frame) = f.tracking_info.y(only_these_flies,current_frame-1);

% % fly positions in last frame --> fly positions in this frame
% f.tracking_info.x(:,current_frame) = f.tracking_info.x(:,current_frame-1);
% f.tracking_info.y(:,current_frame) = f.tracking_info.y(:,current_frame-1);

if ~isempty(f.current_objects)

    % assign objects to flies OK in the last frame
    f = assignObjectsToTheseFlies(f,flies_ok_in_last_frame);


    % find objects that magically get much bigger compared to the previous frame
    f = findSuspectedMergedObjects1(f);


    % resolve interactions
    f = resolveInteractingObjects(f);

    % assign objects to missing flies
    missing_flies = find(f.tracking_info.fly_status(:,f.current_frame) == 2);
    f = assignObjectsToTheseFlies(f,missing_flies);


    % assign objects to away flies
    away_flies = find(f.tracking_info.fly_status(:,f.current_frame) == 3);
    f = assignObjectsToTheseFlies(f,away_flies);


    % are all objects assigned? 
    if any(f.current_object_status <1)
        if any(f.current_object_status == 0)
            % are there any missing flies?
            if any(f.tracking_info.fly_status(:,f.current_frame) == 2)
                % yes
                missing_flies = find(f.tracking_info.fly_status(:,f.current_frame) == 2);
                % assign these objects to these flies 
                f = assignObjectsToTheseFlies(f,missing_flies);

                % after this, assign any unassigned objects to new flies
                f = assignObjectsToNewFlies(f);

            else
                who_will_be_asigned = find(f.current_object_status==0);
                assign_to_this = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first');
                
                % check if we have reached to the end of the allocated space
                if isempty(assign_to_this)
                    % extend the allocated space since we have reached to the max
                    f = extendTrackingInfoPlaceholders(f);
                    assign_to_this = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first');
                end
                
                disp('No misising flies, but we have a nice object that needs assignation. Maybe to a new fly?')
                f = assignObjectsToNewFlies(f);
                % measure only these guys reflection
                for assig_ind = 1:length(who_will_be_asigned)
                    f.frames_ref_meas = [f.frames_ref_meas;[f.current_frame+...
                        f.new_obj_ref_meas_buffer,assign_to_this+assig_ind-1]];
                end

            end
        else
            disp('We have objects that came from split objects, and no flies are missing, so fuck this')
            disp(' ')
        end
    end


    % fix area of interacting flies
    % f = fixInteractArea(f);
end


