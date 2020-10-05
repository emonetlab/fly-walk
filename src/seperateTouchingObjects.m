%% seperateTouchingObjects
% separates touching objects.
% this uses the perimeter of objects to determine if a given object is two objects or not
%  since perimeter is being used, GPUs are not supported
% 
function [f] = seperateTouchingObjects(f)

raw_image = gather(f.current_raw_frame);
L = logical(raw_image);
r = regionprops(L,'Area','Orientation','Centroid','Perimeter');

% remove very small objects as they might be noise
r([r.Area]<f.min_fly_area) = [];

resolve_these = find([r.Perimeter]>f.perimeter_ratio_to_resolve*mean([r.Perimeter]));
r = rmfield(r,'Perimeter');

new_objects = r(1);
new_objects = new_objects(:);
new_objects(1) = [];

if ~isempty(resolve_these)
	if f.ft_debug
		disp('Resolving very large objects...')
	end
else
	disp('Nothing to resolve')
	return
end

for i = 1:length(resolve_these)
	resolve_this = resolve_these(i);

	[split_objects] = splitObject(raw_image,r(resolve_this));
	new_objects = [new_objects split_objects];

end

r(resolve_these) = [];
r = [r(:); new_objects(:)];

if f.ft_debug
	disp(['After perimeter-based object resolution, we have ' oval(length(r)), ' objects.'])
end

% update stuff in the object
f.current_objects = r;