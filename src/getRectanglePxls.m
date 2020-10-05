function XY = getRectanglePxls(x0,y0,len,height,ang)
%getRectanglePxls returns the pixel coordinates in the rectangular box
% x0,y0: coordinates of the starting point (offset point)
% len: length of the rectangle (along x)
% height: width (or height) of the rectangle (orthogonal to d)
% ang: tilt angle from x axis
% 

% start with a box alligned with horizontal
% get box boundaries along x
xbox = 0:round(len);
ybox = -round(height/2):round(height/2);

% get all pixel coordinates in this mesh
[xbox,ybox] = meshgrid(xbox,ybox);
xbox = xbox(:);
ybox = ybox(:);

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
XY(:,1) = round(temprot(:,1) + x0);
XY(:,2) = round(temprot(:,2) + y0);
% XYc(:,1) = ceil(temprot(:,1) + x0);
% XYc(:,2) = ceil(temprot(:,2) + y0);

