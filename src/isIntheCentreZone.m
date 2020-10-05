function status = isIntheCentreZone(f,xy)
%isIntheCentreZone determines if a given point xy is in the central camera
%zone.

camera_pos = [f.ExpParam.camera.x,f.ExpParam.camera.y];

criteria = [xy(1)>(camera_pos(1)+f.center_zone_edge),...
    xy(1)<(camera_pos(1)-f.center_zone_edge),...
    xy(2)>(camera_pos(2)+f.center_zone_edge),...
    xy(2)<(camera_pos(2)-f.center_zone_edge)];

if any(criteria)
    status = false;
else
    status = true;
end
