%% showClosestFly
% indictes the cloest fly to the point given by p
%
function f = showClosestFly(f,p)

if f.current_frame == 1
	x = f.tracking_info.x(:,f.current_frame);
	y = f.tracking_info.y(:,f.current_frame);
else
	x = f.tracking_info.x(:,f.current_frame-1);
	y = f.tracking_info.y(:,f.current_frame-1);
end

d = sqrt((x - p(1)).^2 + (y - p(2)).^2);

d(isnan(d)) = Inf;

[m,idx] = min(d);

if m < 10
	f.ui_handles.fig.Name = ['Fly #' oval(idx)];
else
	f.ui_handles.fig.Name = 'which fly did you mean?';
end