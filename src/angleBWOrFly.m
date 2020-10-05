function angleBWO = angleBWOrFly(f,thisFly,frame1,frame2)
% returns the angle between orientations of the given fly thisFly on frame1
% frame2

or1 = f.tracking_info.orientation(thisFly,frame1);
or2 = f.tracking_info.orientation(thisFly,frame2);
angleBWO = angleBWorientations(or1/180*pi,or2/180*pi)/pi*180;