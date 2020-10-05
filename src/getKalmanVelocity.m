function [vx,vy] = getKalmanVelocity(f,resolve_this,npoints,frame_num)

switch nargin
    case 3
        frame_num = f.current_frame;
    case 2
        frame_num = f.current_frame;
        npoints = f.kalman_length;
end

if frame_num-npoints-1>0
    ax = nanmean(diff(diff(f.tracking_info.x(resolve_this,frame_num-npoints-1:frame_num-1))));
    ay = nanmean(diff(diff(f.tracking_info.y(resolve_this,frame_num-npoints-1:frame_num-1))));
    vx = nanmean(diff(f.tracking_info.x(resolve_this,frame_num-npoints-1:frame_num-1)))+ax;
    vy = nanmean(diff(f.tracking_info.y(resolve_this,frame_num-npoints-1:frame_num-1)))+ay;
else
    ax = nanmean(diff(diff(f.tracking_info.x(resolve_this,1:frame_num-1))));
    ay = nanmean(diff(diff(f.tracking_info.y(resolve_this,1:frame_num-1))));
    vx = nanmean(diff(f.tracking_info.x(resolve_this,1:frame_num-1)))+ax;
    vy = nanmean(diff(f.tracking_info.y(resolve_this,1:frame_num-1)))+ay;
end