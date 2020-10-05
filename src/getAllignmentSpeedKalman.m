function speed = getAllignmentSpeedKalman(f,this_fly)
% returns a logical indicating whether the fly reached to oerinetation
% allignment speed
[vxy(1),vxy(2)] = getKalmanVelocity(f,this_fly,f.nPointsSpeedEstAllign);
speed =  sqrt(vxy(1)^2+vxy(2)^2);