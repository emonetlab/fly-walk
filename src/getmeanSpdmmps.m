function meanSpd = getmeanSpdmmps(f,this_fly,up2thisframe)
% returns the mean speed of the fly for frames from 1 to the requested
% frame number

switch nargin
    case 2
        up2thisframe = f.current_frame;
    case 1
        up2thisframe = f.current_frame;
        how_many_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==0,1,'first')-1;
        this_fly  = 1:how_many_assigned_flies;
end


meanSpd = zeros(length(this_fly),1);
fly_ind = 1;
for i = this_fly
    xvec = f.tracking_info.x(i,1:up2thisframe);
    xvec(isnan(xvec)) = [];
    yvec = f.tracking_info.y(i,1:up2thisframe);
    yvec(isnan(yvec)) = [];
    if isempty(xvec)
        meanSpd(fly_ind) = 0;
    else
        meanSpd(fly_ind) = mean(sqrt(diff(xvec).^2+diff(yvec).^2));
    end
    fly_ind = fly_ind + 1;
end

% convert to mm/sec
meanSpd = meanSpd*f.ExpParam.mm_per_px*f.ExpParam.fps;