function flyKalVel = getFlyKalVel(f,this_fly,kalman_filt_len)
if nargin ==2
    kalman_filt_len = f.nPointsSpeedEstHeading;
end
flyKalVel = zeros(1,size(f.tracking_info.x(this_fly,:),2));

for frame_num = 1:size(f.tracking_info.x(this_fly,:),2)
    [vxy(1),vxy(2)] = getKalmanVelocity(f,this_fly,kalman_filt_len,frame_num);
    flyKalVel(frame_num) = sqrt(vxy(1).^2+vxy(2).^2);
end