function [xr,yr] = rotateTrack(theta,x,y,xc,yc)
%rotateTrack
% [xr,yr] = rotateTrack(theta,x,y,xc,yc)
% rotates a given x, y pair set by theta degrees wrt to x axis around the
% point defined by xc and yc. The default turning point is the origin



% Create rotation matrix
switch nargin
    case 4
        error('needs both xc and yc')
    case 3
        xc = 0; % rotate arounf the origin
        yc = 0; % roatte around the origin
end

% subtract the rotation point
x = x-xc;
y = y-yc;


R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

% columize all x and y to avoid confusion
x2r = x(:);
y2r = y(:);

% Rotate your point(s)
Track2rotate = [x2r';y2r'];
rotatedTrack = R*Track2rotate;
% add the offset bac
xr = reshape(rotatedTrack(1,:),size(x))+xc;
yr = reshape(rotatedTrack(2,:),size(x))+yc;