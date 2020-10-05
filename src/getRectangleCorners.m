function XY = getRectangleCorners(xc,yc,len,height,ang)
%getRectangleCorners retuns the pixel coordinates in the rectangular box
% xc,yc: coordinates of the center point
% len: length of the rectangle (along x)
% height: width (or height) of the rectangel (orthogonal to d)
% ang: tilt angle from x axis
% output order XY = [bl ; br ; tr ;tl]

% start with a box alligned with horizontal
% get box boundaries along x
xbox = [-len/2;len/2;len/2;-len/2];
ybox = [-height/2;-height/2;height/2;height/2];

% convert angle into radian
theta = ang*pi/180;
        
% form the rotation matrix
R = [ cos(theta) sin(theta);...
     -sin(theta) cos(theta)];
         
% rotate the segment and orient it with fly
temprot = R*[xbox,ybox]';
temprot = (temprot)';

%
% add the offset so that the segment falls on the fly
XY(:,1) = (temprot(:,1) + xc);
XY(:,2) = (temprot(:,2) + yc);




