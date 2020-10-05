function heading = getAllignmentHeadingKalman(f,this_fly)
% returns the heading angle of the given fly, estimated by a linear Kalman
% average speed (average length: f.nPointsSpeedEstAllign)
% output is degrees
[vxy(1),vxy(2)] = getKalmanVelocity(f,this_fly,f.nPointsSpeedEstAllign);
heading = mod(cart2pol(vxy(1),vxy(2)),2*pi)/pi*180;
