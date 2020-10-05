%% resolveOverpassingObjects
% resolves possibly overpassing objects on opposite surfaces
% find suspected collision objects on the basis of what happened in the previous frame

function f = resolveOverpassingObjects(f)

if f.current_frame == 1
	return
end

% unpack some data
who_overlaps = find(f.tracking_info.overpassing(:,f.current_frame)>0);

% get colliding objects
who_collides = find(f.tracking_info.collision(:,f.current_frame)>0);

% these flies both collide and overlap
who_does_both = intersect(who_collides,who_overlaps);


if isempty(who_does_both)
        % there are only overlapping guys, so deal with it

    if isempty(who_overlaps)
        % check if there was any
        who_overlaps_prev = find(f.tracking_info.overpassing(:,f.current_frame-1)>0);
        % is this pre-over-lapping fly exists now
        these_prevoverlapping_flies_exist = f.current_object_status(logical(sum(f.current_object_status==(who_overlaps_prev'),2)));
        % remove it from list
        who_overlaps_prev(who_overlaps_prev==these_prevoverlapping_flies_exist) = [];
        
       
        if isempty(who_overlaps_prev)
            return
        else
            who_overlaps = who_overlaps_prev;
        end
        
        % if previously overlapping is missing but there is one object that
        % waits assignment since it just resolved from a collsion,
        % terminate and return
        if length(these_prevoverlapping_flies_exist)>1
            return
        end
        closest_curr_obj = findClosestCurrentObjects(f,these_prevoverlapping_flies_exist,1);
        if (closest_curr_obj(1)==-1)&&any(who_collides==who_overlaps_prev)
            % this object probably collided and resolved
            return
        end
    end

    how_many_overpassers = round(length(who_overlaps)/2);


    if length(who_overlaps)>1

        % do some fact check
        % were these missing flies overpassing in the previous frame
        if (isnan(f.tracking_info.overpassing(who_overlaps(1),f.current_frame-1))&&...       % just started overlapping
                isnan(f.tracking_info.overpassing(who_overlaps(2),f.current_frame-1)))...
                ||((f.tracking_info.overpassing(who_overlaps(1),f.current_frame-1)==who_overlaps(2))... % were both overlapping
                &&(~isempty(f.current_objects(f.current_object_status == -11))))...
                ||(~isempty(f.current_objects(f.current_object_status == -11)))    % one of them was overlapping other was not
            % both just started to overlap or still overlapping and there is an
            % overlapping object

                % which object is the overlapping object
            which_object_overlaps = find(f.current_object_status == -11);
            overlap_objects = f.current_objects(f.current_object_status == -11);
            if numel(overlap_objects)>1
                disp('not assumed that there would be more than 2 overpassers')
                keyboard
            end

            if how_many_overpassers>1
                disp('not assumed that there would be more than 2 overpassers. i.e. two large objects')
                keyboard
            end
            if ~isempty(who_overlaps)
                if f.ft_debug
                    disp('Resolving over-passing objects...')
                end
            else
                return
            end

            for i = 1:how_many_overpassers
                resolve_this = who_overlaps(i);

                % here we assume that fly moves with contant speed and we will predict
                % flies location and register that until overpassing is over

                % which flies are overpassing
                other_fly = who_overlaps(i+1);

                % unpack some data
                r = f.current_objects;
                new_objects = r(1);
                new_objects = new_objects(:);
                new_objects(1) = [];


                % first watershed and compare total area. if area is comparable then
                % use waterhed instead
                [f,split_objects] = splitObjectWaterShed(f,which_object_overlaps);
                if ~isempty(split_objects)
                    rel_area = split_objects(1).Area/split_objects(2).Area;

                    if (rel_area>1.8)||(rel_area<0.3)
                        % there is too much difference
                        if f.ft_debug
                            disp(['area ratio of splitted objects is huge. Rel_area =',num2str(rel_area)])
                        end
                        split_objects = [];
                    end
                end
                if isempty(split_objects)
                    disp('Splitting by k-means...')
                    clean_image = f.current_raw_frame;
                    clean_image(clean_image<f.fly_body_threshold) = 0;
                    split_objects = splitObject(clean_image,r(which_object_overlaps))';
                end
                tot_split_area = sum([split_objects.Area]);
                tot_prev_area = (f.tracking_info.area(resolve_this,f.current_frame-1)+f.tracking_info.area(other_fly,f.current_frame-1));

                if (tot_split_area/tot_prev_area<f.overpass_area_ratio_max)&&(tot_split_area/tot_prev_area>f.overpass_area_ratio_min)
                    % the area change is within 5% error
                    % use watershed

                    % refresh the frame
                    if isfield(f.plot_handles,'ax')
                        if ~isempty(f.plot_handles.ax)
                            f.plot_handles.im.CData = f.current_raw_frame;

                        end
                    end

                    new_objects = catstruct(new_objects, split_objects);

                    r(which_object_overlaps) = [];
                    f.current_object_status(which_object_overlaps) = [];
                    r = [r(:); new_objects(:)];
                    f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];

                    if f.ft_debug
                        disp(['Overpassers are handled by watershed/k-means. Total area diff < ',num2str(100-100*f.overpass_area_ratio_min),'%.'])
                        disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
                        disp('   ')
                    end

                    % update stuff in the object
                    f.current_objects = r;

                else % just estimate the predicted loacations and register
                    % area criteria does not hold. the splitting was not
                    % successful
                    if f.ft_debug
                        disp('Splitting methods did not work. I will predict the locations based on previous speed')
                    end
                    
                    % determine what speed up to use
                        
                    ax = mean(diff(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1))));
                    ay = mean(diff(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1))));
                    vx = mean(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ax;
                    vy = mean(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ay;
                    v_resolve_this = [vx,vy];
                    
                    ax = mean(diff(diff(f.tracking_info.x(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1))));
                    ay = mean(diff(diff(f.tracking_info.y(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1))));
                    vx = mean(diff(f.tracking_info.x(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ax;
                    vy = mean(diff(f.tracking_info.y(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ay;
                    v_other_fly = [vx,vy];
                    
                    % calculate the angle between speed vectors of these
                    % two collidign objects
                    angle = acos(sum(v_other_fly.*v_resolve_this)/norm(v_other_fly)/norm(v_resolve_this));
                    
                    if angle<pi/2
                        % they move in similar paralel directions. use
                        % slower speed to resolve better
                        sudc_ind = 1;
                        if f.ft_debug
                            disp(['Apperently flies: ',mat2str([resolve_this,other_fly]),' move along. Angle: ',num2str(angle,'%1.1f'), ' radians. Slow Down.'])
                        end
                    else
                        % they move in opposite directions. use higher
                        % speed to shoot quickly to other side
                        sudc_ind = 2;
                        if f.ft_debug
                            disp(['Apperently flies: ',mat2str([resolve_this,other_fly]),' move away. Angle: ',num2str(angle,'%1.1f'), ' radians. Speed Up.'])
                        end
                    end
                    
                    % if one of the objects is immobile, use faster speed
                    % anyway
                    if any([isImmobile(f,resolve_this),isImmobile(f,other_fly)])
                        sudc_ind = 2;
                    end
                        

                    % estimate the predicted locations
                    % this object
                    if isImmobile(f,resolve_this)
                        if f.ft_debug
                            disp(['Apperently collision with the immobile fly: ',num2str(resolve_this)] )
                        end
                        f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1);
                        f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1);
                    else
                        
                        f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1)+v_resolve_this(1)*f.speed_up_during_coll(sudc_ind);
                        f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1)+v_resolve_this(2)*f.speed_up_during_coll(sudc_ind);

                        % bound this object by the box
                        xy =   [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)]; 
    %                     xy = boundbyBox(xy,overlap_objects(i).BoundingBox);
                        % get the closest point in the list
                        xy = boundbyPxls(xy,overlap_objects(i).PixelList);
                        f.tracking_info.x(resolve_this,f.current_frame) = xy(1);
                        f.tracking_info.y(resolve_this,f.current_frame) = xy(2);
                        
                    end

                    

                    % other object
                    if isImmobile(f,other_fly)
                        if f.ft_debug
                            disp(['Apperently collision with the immobile fly: ',num2str(other_fly)] )
                        end
                        f.tracking_info.x(other_fly,f.current_frame) = f.tracking_info.x(other_fly,f.current_frame-1);
                        f.tracking_info.y(other_fly,f.current_frame) = f.tracking_info.y(other_fly,f.current_frame-1);
                    else
                        
                        f.tracking_info.x(other_fly,f.current_frame) = f.tracking_info.x(other_fly,f.current_frame-1)+v_other_fly(1)*f.speed_up_during_coll(sudc_ind);
                        f.tracking_info.y(other_fly,f.current_frame) = f.tracking_info.y(other_fly,f.current_frame-1)+v_other_fly(2)*f.speed_up_during_coll(sudc_ind);


                        % bound this object by the box
                        xy =   [f.tracking_info.x(other_fly,f.current_frame),f.tracking_info.y(other_fly,f.current_frame)]; 
    %                     xy = boundbyBox(xy,overlap_objects(i).BoundingBox);
                        % get the closest point in the list
                        xy = boundbyPxls(xy,overlap_objects(i).PixelList);
                        f.tracking_info.x(other_fly,f.current_frame) = xy(1);
                        f.tracking_info.y(other_fly,f.current_frame) = xy(2);
                        
                    end
                    
                    % make 2 new imaginary objects and delete the overlapping guy
                    split_objects(1).Area = f.tracking_info.area(resolve_this,f.current_frame-1);
                    split_objects(2).Area = f.tracking_info.area(other_fly,f.current_frame-1);
                    split_objects(1).Centroid = [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)];
                    split_objects(2).Centroid = [f.tracking_info.x(other_fly,f.current_frame),f.tracking_info.y(other_fly,f.current_frame)];
                    if f.ft_debug
                        disp('assumptions made. fix this in the future. Save major and minor axis too')
                    end
                    split_objects(1).MajorAxisLength = 20; % assume average major length
                    split_objects(2).MajorAxisLength = 20;
                    split_objects(1).MinorAxisLength = 10; % assume average minor length
                    split_objects(2).MinorAxisLength = 10;
                    split_objects(1).Orientation = overlap_objects(i).Orientation;
                    split_objects(2).Orientation = overlap_objects(i).Orientation;

                    new_objects = catstruct(new_objects, split_objects);
                    r(which_object_overlaps) = [];
                    f.current_object_status(which_object_overlaps) = [];
                    r = [r(:); new_objects(:)];
                    f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];

                    if f.ft_debug
                        disp('Overpassers are handled by kalman prediction. Area criteria does not hold')
                        disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
                        disp('   ')
                    end

                    % update stuff in the object
                    f.current_objects = r;


                end



            end

            % clean the overpasser list
            f.overpassing_objects = [];

        end

    else

        % there is no overlapping object. One of the flies is completely under
        % the other one

        these_overlapping_flies_exist = f.current_object_status(logical(sum(f.current_object_status==(who_overlaps'),2)));
        % remove that from list
        who_overlaps(who_overlaps==these_overlapping_flies_exist) = [];

        % fact check, there should be only one fly missing
        if length(who_overlaps)>1
            disp('there must be only one missing fly')
            keyboard
        end
        if isempty(who_overlaps)
            disp('There is not a single fly missing')
            keyboard
        end

        % was it overlapping with another guy in the previous frame
        other_fly = f.tracking_info.overpassing(who_overlaps,f.current_frame-1);
        resolve_this = who_overlaps;
        if f.ft_debug
            disp(['There is not a big object. But there are missing flies (',...
                num2str(other_fly),'). Two of them might be totally overlapping'])
        end
        
        
        if isnan(other_fly)
            disp('it looks like this fly was not overpassing previously')
            disp(['fly: ',mat2str(who_overlaps)])
            keyboard
        end

        % unpack some data
        r = f.current_objects;
        other_object = r(f.current_object_status==other_fly);
        new_objects = r(1);
        new_objects = new_objects(:);
        new_objects(1) = [];

        % determine what speed up to use
        ax = mean(diff(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1))));
        ay = mean(diff(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1))));
        vx = mean(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ax;
        vy = mean(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ay;
        v_resolve_this = [vx,vy];

        ax = mean(diff(diff(f.tracking_info.x(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1))));
        ay = mean(diff(diff(f.tracking_info.y(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1))));
        vx = mean(diff(f.tracking_info.x(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ax;
        vy = mean(diff(f.tracking_info.y(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)))+ay;
        v_other_fly = [vx,vy];

        % calculate the angle between speed vectors of these
        % two collidign objects
        angle = acos(sum(v_other_fly.*v_resolve_this)/norm(v_other_fly)/norm(v_resolve_this));

        if angle<pi/2
            % they move in similar paralel directions. use
            % slower speed to resolve better
            sudc_ind = 1;
            if f.ft_debug
                disp(['Apperently flies: ',mat2str([resolve_this,other_fly]),' move along. Angle: ',num2str(angle,'%1.1f'), ' radians. Slow down.'])
            end
        else
            % they move in opposite directions. use higher
            % speed to shoot quickly to other side
            sudc_ind = 2;
            if f.ft_debug
                disp(['Apperently flies: ',mat2str([resolve_this,other_fly]),' move away. Angle: ',num2str(angle,'%1.1f'), ' radians. Speed Up.'])
            end
        end

        % if one of the objects is immobile, use faster speed
        % anyway
        if any([isImmobile(f,resolve_this),isImmobile(f,other_fly)])
            sudc_ind = 2;
        end
        
        % estimate the predicted location of the missing fly. 
        if isImmobile(f,other_fly)
            if f.ft_debug
                disp(['Apperently collision with the immobile fly: ',num2str(other_fly)] )
            end
            f.tracking_info.x(other_fly,f.current_frame) = f.tracking_info.x(other_fly,f.current_frame-1);
            f.tracking_info.y(other_fly,f.current_frame) = f.tracking_info.y(other_fly,f.current_frame-1);
        else
            

            f.tracking_info.x(other_fly,f.current_frame) = f.tracking_info.x(other_fly,f.current_frame-1)+v_other_fly(1)*f.speed_up_during_coll(sudc_ind);
            f.tracking_info.y(other_fly,f.current_frame) = f.tracking_info.y(other_fly,f.current_frame-1)+v_other_fly(2)*f.speed_up_during_coll(sudc_ind);

            % be more delusional and set the distance between  estimated and
            % measured
%                     f.tracking_info.x(other_fly,f.current_frame) = (f.tracking_info.x(other_fly,f.current_frame)+overlap_objects(i).Centroid(1))/2;
%                     f.tracking_info.y(other_fly,f.current_frame) = (f.tracking_info.y(other_fly,f.current_frame)+overlap_objects(i).Centroid(2))/2;

            % bound this object by the box
            xy =   [f.tracking_info.x(other_fly,f.current_frame),f.tracking_info.y(other_fly,f.current_frame)]; 
%                     xy = boundbyBox(xy,overlap_objects(i).BoundingBox);
            % get the closest point in the list
            xy = boundbyPxls(xy,other_object.PixelList);
            f.tracking_info.x(other_fly,f.current_frame) = xy(1);
            f.tracking_info.y(other_fly,f.current_frame) = xy(2);

        end
        
        % estimate the predicted location of the detected fly and bound 
        if isImmobile(f,resolve_this)
            if f.ft_debug
                disp(['Apperently collision with the immobile fly: ',num2str(resolve_this)] )
            end
            f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1);
            f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1);
        else
            
            f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1)+v_resolve_this(1)*f.speed_up_during_coll(sudc_ind);
            f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1)+v_resolve_this(2)*f.speed_up_during_coll(sudc_ind);

            % be more delusional and set the distance between  estimated and
            % measured
%                     f.tracking_info.x(resolve_this,f.current_frame) = (f.tracking_info.x(resolve_this,f.current_frame)+overlap_objects(i).Centroid(1))/2;
%                     f.tracking_info.y(resolve_this,f.current_frame) = (f.tracking_info.y(resolve_this,f.current_frame)+overlap_objects(i).Centroid(2))/2;

            % bound this object by the box
            xy =   [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)]; 
%                     xy = boundbyBox(xy,overlap_objects(i).BoundingBox);
            % get the closest point in the list
            xy = boundbyPxls(xy,other_object.PixelList);
            f.tracking_info.x(resolve_this,f.current_frame) = xy(1);
            f.tracking_info.y(resolve_this,f.current_frame) = xy(2);

        end
        
        
        % make 2 new imaginary objects and delete the overlapping guy
        split_objects(1).Area = f.tracking_info.area(resolve_this,f.current_frame-1);
        split_objects(2).Area = f.tracking_info.area(other_fly,f.current_frame-1);
        split_objects(1).Centroid = [f.tracking_info.x(other_fly,f.current_frame),f.tracking_info.y(other_fly,f.current_frame)];
        split_objects(2).Centroid = [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)];
        if f.ft_debug
            disp('assumptions made. fix this in the future. Save major and minor axis too')
        end
        split_objects(1).MajorAxisLength = 20; % assume average major length
        split_objects(2).MajorAxisLength = other_object.MajorAxisLength;
        split_objects(1).MinorAxisLength = 10; % assume average minor length
        split_objects(2).MinorAxisLength = other_object.MinorAxisLength;
        split_objects(1).Orientation = other_object.Orientation;
        split_objects(2).Orientation = other_object.Orientation;

        new_objects = catstruct(new_objects, split_objects);
        r(f.current_object_status==other_fly) = [];
        f.current_object_status(f.current_object_status==other_fly) = [];
%         r = [r(:); new_objects(:)];
        r = catstruct(r(:), new_objects(:));
        f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];
        % labell other fly as missing too, and overlapping
        f.tracking_info.fly_status(other_fly,f.current_frame) = 2;
%         f.tracking_info.overpassing(other_fly,f.current_frame) =  resolve_this;
%         f.tracking_info.overpassing(resolve_this,f.current_frame) =  other_fly;

        if f.ft_debug
            disp('Overpassers are handled by kalman prediction. Area criteria does not hold')
            disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
            disp('   ')
        end

        % update stuff in the object
        f.current_objects = r;


    end

    % clean the overpasser list
    f.overpassing_objects = [];
    
else
    % there are both overpassers and colliders
    
    % go over all suspected guys and resolve them
    
    for col_over_obj = 1:length(who_does_both)
        
        this_does_both = who_does_both(col_over_obj);
        opas_pair = f.tracking_info.overpassing(this_does_both,f.current_frame);
        coll_pair = f.tracking_info.collision(this_does_both,f.current_frame);
        
        % fact check, there must be both collider and overpasser
        if ~((length(opas_pair)==1)&&(length(coll_pair)==1))
            disp('there must be both a collider and an overpasser')
            keyboard
        end
        
        which_object_overlaps = find(f.current_object_status == -11);
        overlap_objects = f.current_objects(f.current_object_status == -11);
        
        if numel(overlap_objects)>1
            disp('not assumed that there would be more than 2 overpassers')
            keyboard
        end
        if ~isempty(this_does_both)
            if f.ft_debug
                disp('Resolving over-passing and colliding objects...')
            end
        else
            return
        end

        % unpack some data
        r = f.current_objects;
        new_objects = r(1);
        new_objects = new_objects(:);
        new_objects(1) = [];


        % first watershed and compare total area. if area is comparable then
        % use waterhed instead
        [f,split_objects] = splitObjectWaterShed(f,which_object_overlaps,3);
        if isempty(split_objects)
            disp('Splitting by k-means...')
            clean_image = f.current_raw_frame;
            clean_image(clean_image<f.fly_body_threshold) = 0;
            split_objects = splitObject(clean_image,r(which_object_overlaps),3)';
        end
        tot_split_area = sum([split_objects.Area]);
        tot_prev_area = (f.tracking_info.area(this_does_both,f.current_frame-1)...
            +f.tracking_info.area(opas_pair,f.current_frame-1)...
            +f.tracking_info.area(coll_pair,f.current_frame-1));
%         if (tot_split_area/tot_prev_area<f.overpass_area_ratio_max)&&(tot_split_area/tot_prev_area>f.overpass_area_ratio_min)
        if (tot_split_area/tot_prev_area<1.1)&&(tot_split_area/tot_prev_area>0.9)
            % the area change is within 5% error
            % use watershed

            % refresh the frame
            if isfield(f.plot_handles,'ax')
                if ~isempty(f.plot_handles.ax)
                    f.plot_handles.im.CData = f.current_raw_frame;

                end
            end

            new_objects = catstruct(new_objects, split_objects);

            r(which_object_overlaps) = [];
            f.current_object_status(which_object_overlaps) = [];
            r = [r(:); new_objects(:)];
            f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];

            if f.ft_debug
                disp('Overpassers are handled by watershed. Total area diff < 10%.')
                disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
                disp('   ')
            end

            % update stuff in the object
            f.current_objects = r;

        else % just estimate the predicted loacations and register
            
            % the total area doe not seem to be relevant. now one fly
            % might be totally overlapped and other one is colliding
            % work on that
            
            disp('did not code this yet')
            keyboard

            % estimate the predicted locations
            % this object
            vx = mean(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)));
            vy = mean(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)));
            f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1)+vx;
            f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1)+vy;

            % be more delusional and set the distance between  estimated and
            % measured
            f.tracking_info.x(resolve_this,f.current_frame) = (f.tracking_info.x(resolve_this,f.current_frame)+overlap_objects(i).Centroid(1))/2;
            f.tracking_info.y(resolve_this,f.current_frame) = (f.tracking_info.y(resolve_this,f.current_frame)+overlap_objects(i).Centroid(2))/2;


            % other object
            vx = mean(diff(f.tracking_info.x(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)));
            vy = mean(diff(f.tracking_info.y(other_fly,f.current_frame-f.kalman_length-1:f.current_frame-1)));
            f.tracking_info.x(other_fly,f.current_frame) = f.tracking_info.x(other_fly,f.current_frame-1)+vx;
            f.tracking_info.y(other_fly,f.current_frame) = f.tracking_info.y(other_fly,f.current_frame-1)+vy;


            % be more delusional and set the distance between  estimated and
            % measured
            f.tracking_info.x(other_fly,f.current_frame) = (f.tracking_info.x(other_fly,f.current_frame)+overlap_objects(i).Centroid(1))/2;
            f.tracking_info.y(other_fly,f.current_frame) = (f.tracking_info.y(other_fly,f.current_frame)+overlap_objects(i).Centroid(2))/2;

            % make 2 new imaginary objects and delete the overlapping guy
            split_objects(1).Area = f.tracking_info.area(resolve_this,f.current_frame-1);
            split_objects(2).Area = f.tracking_info.area(other_fly,f.current_frame-1);
            split_objects(1).Centroid = [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)];
            split_objects(2).Centroid = [f.tracking_info.x(other_fly,f.current_frame),f.tracking_info.y(other_fly,f.current_frame)];
            if f.ft_debug
                disp('assumptions made. fix this in the future. Save major and minor axis too')
            end
            split_objects(1).MajorAxisLength = 20; % assume average major length
            split_objects(2).MajorAxisLength = 20;
            split_objects(1).MinorAxisLength = 10; % assume average minor length
            split_objects(2).MinorAxisLength = 10;
            split_objects(1).Orientation = f.tracking_info.orientation(resolve_this,f.current_frame-1);
            split_objects(2).Orientation = f.tracking_info.orientation(other_fly,f.current_frame-1);

            new_objects = catstruct(new_objects, split_objects);
            r(which_object_overlaps) = [];
            f.current_object_status(which_object_overlaps) = [];
            r = [r(:); new_objects(:)];
            f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];

            if f.ft_debug
                disp('Overpassers are handled by kalman prediction. Area criteria does not hold')
                disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
            end

            % update stuff in the object
            f.current_objects = r;


        end

        % clean the overpasser list
        f.overpassing_objects = [];
        f.colliding_objects = [];


%         else
%             if f.ft_debug
%                 disp(['There is not a big object. But there are missing flies. Two ',...
%                 'of them might be totally overlapping'])
%             end
% 
%             % there is no overlapping object. One of the flies is completely under
%             % the other one
% 
%             these_overlapping_flies_exist = f.current_object_status(logical(sum(f.current_object_status==(who_overlaps'),2)));
%             % remove that from list
%             who_overlaps(who_overlaps==these_overlapping_flies_exist) = [];
% 
%             % fact check, there should be only one fly missing
%             if length(who_overlaps)>1
%                 disp('there must be only one missing fly')
%                 keyboard
%             end
%             if isempty(who_overlaps)
%                 disp('There is not a single fly missing')
%                 keyboard
%             end
% 
%             % was it overlapping with another guy in the previous frame
%             other_fly = f.tracking_info.overpassing(who_overlaps,f.current_frame-1);
%             resolve_this = who_overlaps;
%             if isnan(other_fly)
%                 disp('it looks like this fly was not overpassing previously')
%                 disp(['fly: ',mat2str(who_overlaps)])
%                 keyboard
%             end
% 
%             % unpack some data
%             r = f.current_objects;
%             other_object = r(f.current_object_status==other_fly);
%             new_objects = r(1);
%             new_objects = new_objects(:);
%             new_objects(1) = [];
% 
%             % estimate the predicted location of the missing fly. 
%             vx = mean(diff(f.tracking_info.x(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)));
%             vy = mean(diff(f.tracking_info.y(resolve_this,f.current_frame-f.kalman_length-1:f.current_frame-1)));
%             f.tracking_info.x(resolve_this,f.current_frame) = (f.tracking_info.x(resolve_this,f.current_frame-1)+other_object.Centroid(1))/2+vx;
%             f.tracking_info.y(resolve_this,f.current_frame) = (f.tracking_info.y(resolve_this,f.current_frame-1)+other_object.Centroid(2))/2+vy;
% 
%             % make 2 new imaginary objects and delete the overlapping guy
%             split_objects(1).Area = f.tracking_info.area(resolve_this,f.current_frame-1);
%             split_objects(2).Area = f.tracking_info.area(other_fly,f.current_frame-1);
%             split_objects(1).Centroid = [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)];
%             split_objects(2).Centroid = other_object.Centroid;
%             if f.ft_debug
%                 disp('assumptions made. fix this in the future. Save major and minor axis too')
%             end
%             split_objects(1).MajorAxisLength = 20; % assume average major length
%             split_objects(2).MajorAxisLength = other_object.MajorAxisLength;
%             split_objects(1).MinorAxisLength = 10; % assume average minor length
%             split_objects(2).MinorAxisLength = other_object.MinorAxisLength;
%             split_objects(1).Orientation = f.tracking_info.orientation(resolve_this,f.current_frame-1);
%             split_objects(2).Orientation = other_object.Orientation;
% 
%             new_objects = catstruct(new_objects, split_objects);
%             r(f.current_object_status==other_fly) = [];
%             f.current_object_status(f.current_object_status==other_fly) = [];
%             r = [r(:); new_objects(:)];
%             f.current_object_status = [f.current_object_status; -1*ones(length(new_objects),1)];
%             % labell other fly as missing too
%             f.tracking_info.fly_status(other_fly,f.current_frame) = 2;
% 
%             if f.ft_debug
%                 disp('Overpassers are handled by kalman prediction. Area criteria does not hold')
%                 disp(['After collision resolution, we have ' oval(length(r)), ' objects.'])
%             end
% 
%             % update stuff in the object
%             f.current_objects = r;
% 
% 
%         end
% 
%         % clean the overpasser list
%         f.overpassing_objects = [];

        
        
        
        
        
        
        
    end
    
    
end

% 
% if f.ft_debug
% 	disp('Overpassers tracking information is updated')
% end