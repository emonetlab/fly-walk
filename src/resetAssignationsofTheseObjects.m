function f = resetAssignationsofTheseObjects(f,reset_these_flies)
% reset the assignations of these objects

f.tracking_info.fly_status(reset_these_flies,f.current_frame) = 2;
f.tracking_info.area(reset_these_flies,f.current_frame) = NaN;
f.tracking_info.x(reset_these_flies,f.current_frame) = f.tracking_info.x(reset_these_flies,f.current_frame-1);
f.tracking_info.y(reset_these_flies,f.current_frame) = f.tracking_info.y(reset_these_flies,f.current_frame-1);
f.tracking_info.heading(reset_these_flies,f.current_frame) = NaN;
f.tracking_info.orientation(reset_these_flies,f.current_frame) = NaN;