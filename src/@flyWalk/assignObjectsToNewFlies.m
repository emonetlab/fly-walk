%% assignObjectsToNewFlies
% assigns all unassigned objects to new flies
% this function assigns all unassigned objects (as determined by f.current_object_status)
% to new flies

function f = assignObjectsToNewFlies(f)

a = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first');

% check if we have reached to the end of the allocated space
if isempty(a)
    % extend the allocated space since we have reached to the max
    f = extendTrackingInfoPlaceholders(f);
    a = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first');
end

% who are we assigning
assign_these = find(f.current_object_status==0);


for i = 1:length(assign_these)
    
    if ~(f.current_frame ==1)
        % if that is a lost fly in the periphery ignore
        to_this_fly = isAssignedtoLostFly(f,f.current_objects(assign_these(i)).Centroid);
        if ~isempty(to_this_fly)
            if f.ft_debug
                disp(['a new fly is matched to the lost fly: ', ...
                    mat2str(to_this_fly),' at the periphery. Ignoring...'])
                a = a-1;    % adjust the assignation number
            end
            continue
        end
    end
    
    
    f.tracking_info.x(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).Centroid(1);
    f.tracking_info.y(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).Centroid(2);
    f.tracking_info.fly_status(a+i-1,f.current_frame) = 1;
    if ~isempty(f.current_objects(assign_these(i)).Orientation)
        if isnan(f.current_objects(assign_these(i)).Orientation)
            f.tracking_info.orientation(a+i-1,f.current_frame) = f.tracking_info.orientation(a+i-1,f.current_frame-1);
        else
            f.tracking_info.orientation(a+i-1,f.current_frame) = mod(-f.current_objects(assign_these(i)).Orientation,360);
        end
    else
        f.tracking_info.orientation(a+i-1,f.current_frame) = f.tracking_info.orientation(a+i-1,f.current_frame-1);
    end
    
    fields2look = {'Area','MajorAxisLength','MinorAxisLength','Perimeter','Eccentricity'};
    fields2write = {'area','majax','minax','perimeter','excent'};
    for ii = 1:length(fields2look)
        try
            if ~isempty(f.current_objects(assign_these(i)).(fields2look{ii}))
                f.tracking_info.(fields2write{ii})(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).(fields2look{ii});
            else
                f.tracking_info.(fields2write{ii})(a+i-1,f.current_frame) = f.tracking_info.(fields2write{ii})(a+i-1,f.current_frame-1);
            end
        catch
        end
    end
    
    %     f.tracking_info.area(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).Area;
    %     f.tracking_info.orientation(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).Orientation;
    %     f.tracking_info.majax(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).MajorAxisLength; % major axis
    %     f.tracking_info.minax(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).MinorAxisLength; % major axis
    %change the current object status
    f.current_object_status(assign_these(i)) = a+i-1;
    if isfield(f.current_objects,'RFluo')
        f.reflection_meas(a+i-1,f.current_frame) = f.current_objects(assign_these(i)).RFluo;
        f.reflection_status(a+i-1) = mean(nonzeros(f.reflection_meas(a+i-1,1:f.current_frame)))>f.ref_thresh;
    end
    
    if (f.current_frame ~=1)
        % take care of reflections of flies at the periphery
        if (f.tracking_info.fly_status(a+i-1,f.current_frame-1)==2)...
                ||(f.tracking_info.fly_status(a+i-1,f.current_frame-1)==0)
            f.frames_ref_meas = [f.frames_ref_meas;[f.current_frame+...
                f.new_obj_ref_meas_buffer,a+i-1]];
        end
        
        if isIntheCentreZone(f,f.current_objects(assign_these(i)).Centroid)
            f.flies_in_the_centre_zone = [f.flies_in_the_centre_zone,a+i-1];
            if f.ft_debug
                disp(['New fly:', num2str(a+i-1),' is added to centre zone list'])
            end
        end
        
    end
    
end