function angle = angleBWorientations(Orient1,Orient2)
% gets the angle between two vectors with orientations Orient 1 and Orient2
% input is radians

[x1,y1] = pol2cart(Orient1,1); % make a unit vector
v1 = [x1,y1];
[x2,y2] = pol2cart(Orient2,1); % make a unit vector
v2 = [x2,y2];

angle = acos(sum(v1.*v2)/norm(v1)/norm(v2));