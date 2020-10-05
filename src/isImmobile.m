function status = isImmobile(f,these_flies,up2thisframe)
%isImmobile determine if the fly(s) is immobile. criteria is defined as in
% f.immobile_speed

switch nargin
    case 2
        up2thisframe = f.current_frame;
    case 1
        up2thisframe = f.current_frame;
        how_many_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first')-1;
        these_flies  = 1:how_many_assigned_flies;
end

% get mean speeds
meanSpd = getmeanSpd(f,these_flies,up2thisframe);

status = meanSpd<f.immobile_speed;