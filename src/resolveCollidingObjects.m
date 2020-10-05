%% resolveCollidingObjects
% resolves possibly colliding objects
% find suspected collision objects on the basis of what happened in the previous frame

function f = resolveCollidingObjects(f)

if f.current_frame == 1
	return
end


% unpack some data
r = f.current_objects;

resolve_these = find(f.current_object_status == -1);

new_objects = r(1);
new_objects = new_objects(:);
new_objects(1) = [];

if ~isempty(resolve_these)
	if f.ft_debug
		disp('Resolving very large objects...')
	end
else
	return
end

for i = 1:length(resolve_these)
	resolve_this = resolve_these(i);



    
    [f,split_objects] = splitObjectWaterShed(f,resolve_this);
    
    %areas must be reasonable
    rel_area = split_objects(1).Area/split_objects(2).Area;
    
    if (rel_area>1.5)||(rel_area<0.5)
        % there is too much difference
        if f.ft_debug
            disp(['area ratio of splitted objects is huge. Rel_area =',num2str(rel_area)])
        end
        split_objects = [];
    end
    
    % try k-means
    if isempty(split_objects)
        disp('Splitting by k-means...')
        clean_image = f.current_raw_frame;
        clean_image(clean_image<f.fly_body_threshold) = 0;
        split_objects = splitObject(clean_image,r(resolve_this))';
    end
        
    % refresh the frame
    if isfield(f.plot_handles,'ax')
		if ~isempty(f.plot_handles.ax)
			f.plot_handles.im.CData = f.current_raw_frame;
					
		end
    end
    
%     new_objects = [new_objects split_objects];
    new_objects = catstruct(new_objects, split_objects);
    


end

r(resolve_these) = [];
f.current_object_status(resolve_these) = [];
r = [r(:); new_objects(:)];
f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];

if f.ft_debug
	disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
    disp('   ')
end

% clean the list
f.colliding_objects = [];

% update stuff in the object
f.current_objects = r;