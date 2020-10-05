% handleCentreZoneReflection
% measures the reflections of the objects that were in the centre zone when
% ever they get out of the zone.
%
function f = handleCentreZoneReflection(f)

if isempty(f.flies_in_the_centre_zone)
    return
end
to_be_deleted = [];
% check if any of these got out of the zone
for i = 1:length(f.flies_in_the_centre_zone)
    this_fly = f.flies_in_the_centre_zone(i);
    % is it still in the zone
    if isIntheCentreZone(f,[f.tracking_info.x(this_fly,f.current_frame),f.tracking_info.y(this_fly,f.current_frame)])
        continue
    else
        to_be_deleted = [to_be_deleted,i];
        % measure its reflection
        f = handleThisObjectsReflection(f,this_fly);
        if f.ft_debug
            disp(['fly: ',num2str(this_fly),' exited the centre reflection zone'])
            if f.reflection_status(this_fly,f.current_frame)
                disp(['fly: ',num2str(this_fly),' has reflection'])
            else
                disp(['fly: ',num2str(this_fly),' has NO reflection'])
            end
        end
    end
end

% delete the exted ones
f.flies_in_the_centre_zone(to_be_deleted) = [];
    

