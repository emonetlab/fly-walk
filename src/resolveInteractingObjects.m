%% resolveInteractingObjects
% resolves possibly overpassing objects on opposite surfaces
% find suspected collision objects on the basis of what happened in the previous frame

function f = resolveInteractingObjects(f)

if f.current_frame == 1
	return
end

% unpack some data
if isempty(f.interaction_list)
    return
end

% set an empty frame in case program does not reach to watershed
crf = f.current_raw_frame;

% go over the list and apply the best method to resolve
while ~isempty(f.interaction_list)
    % get the interaction id's
    resolve_these = f.interaction_list{1};
    % remove from the list
    f.interaction_list(1) = [];
    % how many flies interact
    switch length(resolve_these)
        case 1
            disp('there must be at least two flies interacting')
            keyboard
        case 2
            % two flies can be colliding or overlapping
            
            if f.ft_debug
                if sign(resolve_these(1)*resolve_these(2))==1
                    disp(['Resolving Colliders: ',mat2str(resolve_these)])
                else
                    disp(['Resolving Overlappers: ',mat2str(resolve_these)])
                end
            end
             
            resolve_this = abs(resolve_these(1));
            % get the overlapping object
            if isempty(find(f.current_object_status==resolve_this, 1))&&(~isempty(find(f.current_object_status==-resolve_this, 1)))
                which_object_overlaps = find(f.current_object_status==-resolve_this);
            elseif ~isempty(find(f.current_object_status==resolve_this, 1))
                which_object_overlaps = find(f.current_object_status==resolve_this);
            end

            % which fly is interacting
            other_fly = abs(resolve_these(2));

            % unpack some data
            r = f.current_objects;
            new_objects = r(1);
            new_objects = new_objects(:);
            new_objects(1) = [];
            
            if sign(f.current_object_status(which_object_overlaps))==1 
                % if there is not a large object go directly to estimation
                
                % first watershed and compare total area. if area is comparable then
                % use waterhed instead
                [f,split_objects] = splitObjectWaterShed(f,which_object_overlaps);
                if ~isempty(split_objects)
                    rel_area = split_objects(1).Area/split_objects(2).Area;
                    if rel_area<1
                        rel_area = 1/rel_area;
                    end
                    rel_area_prev = f.tracking_info.area(abs(resolve_these(1)),f.current_frame-1)/...
                        f.tracking_info.area(abs(resolve_these(2)),f.current_frame-1);
                    if rel_area_prev<1
                        rel_area_prev = 1/rel_area_prev;
                    end
                    
                    RelArea = rel_area_prev/rel_area;
                    if RelArea<1
                        RelArea = 1/RelArea;
                    end

%                     if (rel_area>(1+f.collision_rel_area_tolerance))||(rel_area<(1-f.collision_rel_area_tolerance))
                    if RelArea>(1+f.interaction_rel_area_tolerance)
                        % there is too much difference
                        if f.ft_debug
                            disp(['Splitted objects are disproportionate. Rel_area =',num2str(RelArea)])
                        end
                        split_objects = [];
                    end
                end

                % if failed use k-means
                if isempty(split_objects)&&f.include_kmeans
                    disp('Watershed did not work. Splitting by k-means...')
                    clean_image = f.current_raw_frame;
                    clean_image(clean_image<f.fly_body_threshold) = 0;
                    split_objects = splitObject(clean_image,r(which_object_overlaps))';
                end
                
                if ~isempty(split_objects)
                    tot_split_area = sum([split_objects.Area]);
                    tot_prev_area = (f.tracking_info.area(resolve_this,f.current_frame-1)+f.tracking_info.area(other_fly,f.current_frame-1));

                    % is any of the splitted guys in jumping distance
                    jumping_split_objects = findJumpingSplitObjects(f,split_objects,resolve_these);
                    if f.ft_debug&&~isempty(jumping_split_objects)
                        disp(['After the split, fly(s): ',mat2str(jumping_split_objects),' seem(s) to be jumping. Will use position prediction instead'])
                    end
                else
                    % set this to swicth directly to estimation
                    tot_split_area = 0;
                    tot_prev_area = 1;
                    jumping_split_objects = [];
                end

            else
                % set this to swicth directly to estimation
                tot_split_area = 0;
                tot_prev_area = 1;
                jumping_split_objects = [];
            end
            
            % set the area tolerance
            if sign(resolve_these(1)*resolve_these(2))==1
                area_tolerance = f.collision_tot_area_tolerance;
            else
                area_tolerance = f.overpass_tot_area_tolerance(length(resolve_these)-1);
            end
            
            
            
            % compare areas, or directly estimate the positions
            if (((tot_split_area/tot_prev_area)<(1+area_tolerance))&&...
                    ((tot_split_area/tot_prev_area)>(1-area_tolerance))...
                    && sign(f.current_object_status(which_object_overlaps))==1)...
                    &&isempty(jumping_split_objects)
                % the area change is within tolerance
                % use the splitted objects
                % refresh the frame
                if isfield(f.plot_handles,'ax')
                    if ~isempty(f.plot_handles.ax)
                        f.plot_handles.im.CData = uint8(f.current_raw_frame);

                    end
                end
                
                % curate immobile guys
                split_objects = CurateSplitObjects(f,split_objects,resolve_these);
                
                new_objects = catstruct(new_objects, split_objects);
                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                r = [r(:); new_objects(:)];
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                if f.ft_debug
                    disp(['Interacting flies are handled by watershed/k-means. Total area diff < ',num2str(100*area_tolerance),'%.'])
                    disp('   ')
                end

                % update stuff in the object
                f.current_objects = r;


            else % just estimate the predicted locations and register
                % area criteria does not hold. the splitting was not
                % successful
                if f.ft_debug
                    if sign(resolve_these(1)*resolve_these(2))==1
                        disp('Collision expected but it looks like they are overpassing. Or, the collision total area tolerance is too harsh.')
                        f.tracking_info.error_code(abs(resolve_these(1)),f.current_frame) = 1; % reflection mismatch
                        f.tracking_info.error_code(abs(resolve_these(2)),f.current_frame) = 1; % reflection mismatch
                    end
                end
                
                % try fitting ellipses
                if f.include_ellips_fit
                    f.current_raw_frame = crf;
                    [split_objects,bestFits] = fitEllipstoFlies(f,which_object_overlaps,abs(resolve_these));
                    % experiment ellips fit here
                else
                    split_objects = [];
                end
                
                if isempty(split_objects)||any(sum(isnan(bestFits),1))
                    % predict location by previous locations, speed, and
                    % acceleration
                    split_objects = PredictPositions(f,resolve_these,which_object_overlaps);
                else
                    if f.ft_debug
                        disp(['Flies: ',mat2str(abs(resolve_these)),' are resolved by fitting ellipses.'])
                        disp('   ')
                    end
                    f.best_ellips_fits = bestFits;
                end

                new_objects = catstruct(new_objects, split_objects);
                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                r = catstruct(r(:),new_objects(:));
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                % update stuff in the object
                f.current_objects = r;


            end
            
        case 3
            % there are both overpassers and colliders
            if f.ft_debug
                disp(['Resolving interacting flies: ',mat2str(resolve_these)])
            end
             
            resolve_this = abs(resolve_these(1));
            
            % get the overlapping object
            if isempty(find(f.current_object_status==resolve_this, 1))&&(~isempty(find(f.current_object_status==-resolve_this, 1)))
                which_object_overlaps = find(f.current_object_status==-resolve_this);
            elseif ~isempty(find(f.current_object_status==resolve_this, 1))
                which_object_overlaps = find(f.current_object_status==resolve_this);
            end

            % get interaction pairs
            opas_pair = abs(resolve_these(3));
            coll_pair = abs(resolve_these(2));
            
            % unpack some data
            r = f.current_objects;
            new_objects = r(1);
            new_objects = new_objects(:);
            new_objects(1) = [];
            
            if sign(f.current_object_status(which_object_overlaps))==1 
                % if there is not a large object go directly to estimation

                % first watershed and compare total area. if area is comparable then
                % use waterhed instead
                [f,split_objects] = splitObjectWaterShed(f,which_object_overlaps,3);
                if isempty(split_objects)&&f.include_kmeans
                    disp('Watershed did not work. Splitting by k-means...')
                    clean_image = f.current_raw_frame;
                    clean_image(clean_image<f.fly_body_threshold) = 0;
                    split_objects = splitObject(clean_image,r(which_object_overlaps),3)';
                end
                
          
            
                if ~isempty(split_objects)
                    tot_split_area = sum([split_objects.Area]);
                    RelArea = zeros(numel(split_objects));
                    for j = 1:length(split_objects)
                        RelArea(1,j) = f.tracking_info.area(resolve_this,f.current_frame-1)/split_objects(j).Area;
                        if RelArea(1,j)<1
                            RelArea(1,j) = 1/RelArea(1,j);
                        end
                        RelArea(2,j) = f.tracking_info.area(opas_pair,f.current_frame-1)/split_objects(j).Area;
                        if RelArea(2,j)<1
                            RelArea(2,j) = 1/RelArea(2,j);
                        end
                        RelArea(3,j) = f.tracking_info.area(coll_pair,f.current_frame-1)/split_objects(j).Area;
                        if RelArea(3,j)<1
                            RelArea(3,j) = 1/RelArea(3,j);
                        end
                    end
                    tot_prev_area = (f.tracking_info.area(resolve_this,f.current_frame-1)...
                        +f.tracking_info.area(opas_pair,f.current_frame-1)...
                        +f.tracking_info.area(coll_pair,f.current_frame-1));
                    


                    % is any of the splitted guys in jumping distance
                    jumping_split_objects = findJumpingSplitObjects(f,split_objects,resolve_these);
                    if f.ft_debug&&~isempty(jumping_split_objects)
                        disp(['After the split, fly(s): ',mat2str(jumping_split_objects),' seem(s) to be jumping. Will use position prediction instead'])
                    end
                    
                    if any(min(RelArea,[],1)>(1+f.interaction_rel_area_tolerance))
                        % there is too much difference
                        if f.ft_debug
                            disp(['Splitted objects are disproportionate. Rel_area =',mat2str(min(RelArea,[],1),2)])
                        end
                        split_objects = [];
                        tot_split_area = 0;
                        tot_prev_area = 1;
                        jumping_split_objects = [];
                    end
                else
                    % set this to swicth directly to estimation
                    tot_split_area = 0;
                    tot_prev_area = 1;
                    jumping_split_objects = [];
                end
                
                
            else
                % set this to swicth directly to estimation
                tot_split_area = 0;
                tot_prev_area = 1;
                jumping_split_objects = [];
            end
            
            area_tolerance = f.overpass_tot_area_tolerance(length(resolve_these)-1);
            
            
            
            % compare areas, or directly estimate the positions
            if (((tot_split_area/tot_prev_area)<(1+area_tolerance))&&...
                    ((tot_split_area/tot_prev_area)>(1-area_tolerance))...
                    && sign(f.current_object_status(which_object_overlaps))==1)...
                    && isempty(jumping_split_objects)
                % refresh the frame
                if isfield(f.plot_handles,'ax')
                    if ~isempty(f.plot_handles.ax)
                        f.plot_handles.im.CData = uint8(f.current_raw_frame);

                    end
                end

                % curate imoobile guys
                split_objects = CurateSplitObjects(f,split_objects,resolve_these);
                
                new_objects = catstruct(new_objects, split_objects);

                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                r = [r(:); new_objects(:)];
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                if f.ft_debug
                    disp(['Interacting flies are handled by separation. Total area diff < ',num2str(100*area_tolerance),'%.'])
                    disp('   ')
                end

                % update stuff in the object
                f.current_objects = r;

            else % just estimate the predicted loacations and register

                % the total area doe not seem to be relevant. now one fly
                % might be totally overlapped and other one is colliding
                % work on that
                
                if f.include_ellips_fit
                    % try fitting ellipses
                    f.current_raw_frame = crf;
                    [split_objects,bestFits] = fitEllipstoFlies(f,which_object_overlaps,abs(resolve_these));
                    % experiment ellips fit here
                else
                    split_objects = [];
                end
                
                if isempty(split_objects)||any(sum(isnan(bestFits),1))
                    % predict location by previous locations, speed, and
                    % acceleration
                    split_objects = PredictPositions(f,resolve_these,which_object_overlaps);
                else
                    if f.ft_debug
                        disp(['Flies: ',mat2str(abs(resolve_these)),' are resolved by fitting ellipses.'])
                        disp('   ')
                    end
                    f.best_ellips_fits = bestFits;
                end
                
                new_objects = catstruct(new_objects, split_objects);
                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                r = catstruct(r(:),new_objects(:));
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                % update stuff in the object
                f.current_objects = r;
            end
            
        otherwise
            
            disp('There are 4 or more flies interacting. I will let the code give a shot to that')
            disp(['Interacting flies: ',mat2str(resolve_these)])
            
            % again start with splitting than estimate
            resolve_this = abs(resolve_these(1));
            
            % get the overlapping object
            if isempty(find(f.current_object_status==resolve_this, 1))&&(~isempty(find(f.current_object_status==-resolve_this, 1)))
                which_object_overlaps = find(f.current_object_status==-resolve_this);
            elseif ~isempty(find(f.current_object_status==resolve_this, 1))
                which_object_overlaps = find(f.current_object_status==resolve_this);
            end

            
            % unpack some data
            r = f.current_objects;
            new_objects = r(1);
            new_objects = new_objects(:);
            new_objects(1) = [];
            
            if sign(f.current_object_status(which_object_overlaps))==1 
                % if there is not a large object go directly to estimation

                % first watershed and compare total area. if area is comparable then
                % use waterhed instead
                [f,split_objects] = splitObjectWaterShed(f,which_object_overlaps,length(resolve_these));
                if isempty(split_objects)&&f.include_kmeans
                    disp('Watershed did not work. Splitting by k-means...')
                    clean_image = f.current_raw_frame;
                    clean_image(clean_image<f.fly_body_threshold) = 0;
                    split_objects = splitObject(clean_image,r(which_object_overlaps),3)';
                end
                
                if ~isempty(split_objects)
                    tot_split_area = sum([split_objects.Area]);
                    tot_prev_area = 0;
                    RelArea = zeros(numel(split_objects));
                    for i = 1:length(resolve_these)
                        tot_prev_area = tot_prev_area + f.tracking_info.area(abs(resolve_these(i)),f.current_frame-1);
                        for j = 1:length(resolve_these)
                            RelArea(i,j) = f.tracking_info.area(abs(resolve_these(i)),f.current_frame-1)/split_objects(j).Area;
                            if RelArea(i,j)<1
                                RelArea(i,j) = 1/RelArea(i,j);
                            end
                        end
                    end


                    % is any of the splitted guys in jumping distance
                    jumping_split_objects = findJumpingSplitObjects(f,split_objects,resolve_these);
                    if f.ft_debug&&~isempty(jumping_split_objects)
                        disp(['After the split, fly(s): ',mat2str(jumping_split_objects),' seem(s) to be jumping. Will use position prediction instead'])
                    end
                 if any(min(RelArea,[],1)>(1+f.interaction_rel_area_tolerance))
                    % there is too much difference
                    if f.ft_debug
                        disp(['Splitted objects are disproportionate. Rel_area =',mat2str(min(RelArea,[],1),2)])
                    end
                    split_objects = [];
                    tot_split_area = 0;
                    tot_prev_area = 1;
                    jumping_split_objects = [];
                end
                
                else
                    % set this to swicth directly to estimation
                    tot_split_area = 0;
                    tot_prev_area = 1;
                    jumping_split_objects = [];
                end
                
                

            else
                % set this to swicth directly to estimation
                tot_split_area = 0;
                tot_prev_area = 1;
                jumping_split_objects = [];
            end
            
            area_tolerance = f.overpass_tot_area_tolerance(2);
            
            
            
            % compare areas, or directly estimate the positions
            if (((tot_split_area/tot_prev_area)<(1+area_tolerance))&&...
                    ((tot_split_area/tot_prev_area)>(1-area_tolerance))...
                    && sign(f.current_object_status(which_object_overlaps))==1)...
                    && isempty(jumping_split_objects)
                % refresh the frame
                if isfield(f.plot_handles,'ax')
                    if ~isempty(f.plot_handles.ax)
                        f.plot_handles.im.CData = uint8(f.current_raw_frame);

                    end
                end

                % curate imoobile guys
                split_objects = CurateSplitObjects(f,split_objects,resolve_these);
                
                new_objects = catstruct(new_objects, split_objects);

                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                r = [r(:); new_objects(:)];
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                if f.ft_debug
                    disp(['Interacting flies are handled by separation. Total area diff < ',num2str(100*area_tolerance),'%.'])
                    disp('   ')
                end

                % update stuff in the object
                f.current_objects = r;

            else % just estimate the predicted loacations and register

                % the total area doe not seem to be relevant. now one fly
                % might be totally overlapped and other one is colliding
                % work on that
                
                if f.include_ellips_fit
                    % try fitting ellipses
                    f.current_raw_frame = crf;
                    [split_objects,bestFits] = fitEllipstoFlies(f,which_object_overlaps,abs(resolve_these));
                    % experiment ellips fit here
                else
                    split_objects = [];
                end
                
                if isempty(split_objects)||any(sum(isnan(bestFits),1))
                    % predict location by previous locations, speed, and
                    % acceleration
                    split_objects = PredictPositions(f,resolve_these,which_object_overlaps);
                else
                    f.best_ellips_fits = bestFits;
                    if f.ft_debug
                        disp(['Flies: ',mat2str(abs(resolve_these)),' are resolved by fitting ellipses.'])
                        disp('   ')
                    end
                end
                
                % deleting the objects causes problems with other
                % interacting objects. just label it as pi then delete them
%                 r(which_object_overlaps) = [];
                f.current_object_status(which_object_overlaps) = pi;
                f.current_object_status(which_object_overlaps) = [];
                r = catstruct(r(:),new_objects(:));
                f.current_object_status = [f.current_object_status; -1111*ones(length(new_objects),1)];

                % update stuff in the object
                f.current_objects = r;
            end
            
                
    end
end

% now delete the unused ones
r(f.current_object_status==pi) = [];
f.current_object_status(f.current_object_status==pi) = [];
f.current_objects = r;


