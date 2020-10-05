function state = isAtKalmanAlligmentSpeed(f,this_fly)
% returns a logical indicating whether the fly reached to oerinetation
% allignment speed

state = getAllignmentSpeedKalman(f,this_fly)>(f.immobile_speed*f.heading_allignment_factor);
                   