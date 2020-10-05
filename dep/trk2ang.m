function [theta,dtheta] = trk2ang(x,y)
% trk2ang
% return the angle values and angle deviations along the trajectory whose x
% and y are given

xd = diff(x);
yd = diff(y);
[THETA,~] = cart2pol(xd,yd);
theta = mod(THETA*180/pi,360);
dtheta = zeros(size(theta));
for i = 1:length(xd)-1
    dtheta(i) = angleDiff(THETA(i+1), THETA(i));
end
dtheta = dtheta*180/pi;
% dtheta(2:end) = diff(theta);
% dtheta(dtheta>300) = dtheta(dtheta>300)-360;
% dtheta(dtheta<-300) = 360+dtheta(dtheta<-300);