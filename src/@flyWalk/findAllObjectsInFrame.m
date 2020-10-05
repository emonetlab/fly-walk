% findAllObjectsInFrame.m
% reads frame from .mat file and finds all the objects in that frame
% returns a regionprops structure array
% 
function f = findAllObjectsInFrame(f)


% eval(['raw_image = f.path_name.' f.variable_name '(:,:,f.current_frame);']);
% if f.use_gpu
% 	raw_image = gpuArray(raw_image);
% else
% end
% raw_image(f.mask==0) = 0;

raw_image = f.current_raw_frame;
raw_image(raw_image<f.fly_body_threshold) = 0;
L = logical(raw_image);
r = regionprops(L,f.regionprops_args);

% remove very small objects as they might be noise
r([r.Area]<f.min_fly_area) = [];


% add to the object
f.current_objects = r;
f.current_object_status = zeros(length(r),1);

if f.ft_debug
	disp(['current_frame:	' oval(f.current_frame), '  ', oval(length(r)), ' objects found.'])
end

