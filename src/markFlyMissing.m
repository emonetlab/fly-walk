%% markFlyMissing
% this is a subfunction meant to be called by mapObjectsOntoFlies
% 

function [tracking_info] = markFlyMissing(tracking_info,this_fly,current_frame)
	% inherit the location from the previous frame
	tracking_info.x(this_fly,current_frame) = tracking_info.x(this_fly,current_frame-1);
	tracking_info.y(this_fly,current_frame) = tracking_info.y(this_fly,current_frame-1);
	tracking_info.area(this_fly,current_frame) = tracking_info.area(this_fly,current_frame-1);
	tracking_info.fly_status(this_fly,current_frame) = 2; % mark it as missing
    

    
end