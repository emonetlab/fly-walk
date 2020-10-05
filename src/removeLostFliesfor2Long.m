function f = removeLostFliesfor2Long(f)

% which flies seem to be lost for too long: look_for_lost_flies_length

these_flies_are_lost_now = find(f.tracking_info.fly_status(:,f.current_frame)>1);

% go over and terminate if lost too long

if isempty(these_flies_are_lost_now)
    return
end

for i = 1:length(these_flies_are_lost_now)
    this_lost_fly = these_flies_are_lost_now(i);
    if (getLostTime(f,this_lost_fly))>=f.look_for_lost_flies_length
        % terminate this guy
        f.tracking_info.fly_status(this_lost_fly,f.current_frame) = NaN;
        if f.ft_debug
            disp(['fly: ',num2str(this_lost_fly),' is lost for ',num2str(f.look_for_lost_flies_length),' seconds. Terminating...'])
            disp(' ')
        end
    end
end