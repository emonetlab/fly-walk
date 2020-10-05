%% f = findSuspectedMergedObjects(f);
% finds objects that are suspiciously large compared to the fly area in the last frame
%
function f = findSuspectedMergedObjects(f)

% get the list of missing flies
who_misses_currently = find(f.tracking_info.fly_status(:,f.current_frame)==2);
% may be the flies just exited remove them
who_misses_currently(isFlyInthePeriferi(f,who_misses_currently)) = [];
who_is_handled_so_far = Inf; % accumulate the handled flies in here
if isempty(who_misses_currently)
    return
end

r = f.current_objects;
delta_area = NaN(length(r),1);

for i = 1:length(r)
	if f.current_object_status(i) > 0 
		% this has been assigned
		% find the area of the fly it corresponds to in the previous frame
		prev_frame_area = f.tracking_info.area(f.current_object_status(i),f.current_frame-1);
        if isnan(prev_frame_area)
            prev_frame_area = median(f.tracking_info.area(~isnan(f.tracking_info.area(:,f.current_frame-1)),f.current_frame-1));
            if f.ft_debug
                disp(['fly: ',num2str(f.current_object_status(i)),' seems to be assigned now. I will use median area instead.'])
            end
        end
		delta_area(i) = r(i).Area/prev_frame_area;
	end
end


% colliding or overpassing with one object
suspected_merged_objects = logical((delta_area > f.doubled_fly_area_ratio).*(delta_area < f.tripled_fly_area_ratio));
reset_these_flies = f.current_object_status(suspected_merged_objects);

% there might be misdetected triple interaction
triple_interact_flies = [];


% mark the objects as suspected of being merged objects
for i = 1:length(reset_these_flies)
    this_fly = reset_these_flies(i);
    this_object = f.current_objects(f.current_object_status==this_fly);
    if isIntheCollignoreZone(f,this_object.Centroid)
        % just ignore all collisions if the object is close to the
        % boundary. it becomes very complicated to resolve collisions when
        % flies are about to enter or exit. change the boundary size and
        % experiment the effect: edge_coll_ignore_dist
        continue
    else

        % fact check, there should be one suspected fly
        suspected_flies = findSuspectedInteractingFlies(f,this_fly)';
        prev_ints = getInteractions(f,[this_fly,suspected_flies]);
        % get flies close to given fly, get 9 closest ones
        closer_flies = findClosestFlies(f,this_fly,9);
        % remove the ones far away
        closer_flies(closer_flies(:,2)>f.close_fly_distance,:) = [];
        % get only the close interactions
        prev_ints = intersect(prev_ints,closer_flies(:,1)');
                
        suspected_flies = unique([suspected_flies,prev_ints]);
        

        if ~isempty(suspected_flies)
            % remove existing flies
            suspected_flies(logical(sum(suspected_flies==f.current_object_status,1))) = [];
            suspected_flies(suspected_flies==this_fly) = [];
            suspected_flies(logical(sum(suspected_flies==who_is_handled_so_far,1))) = []; 
        end
        if length(suspected_flies)==2
            if f.ft_debug
                disp(['this fly (',num2str(this_fly),') looks like a double fly, but there are two missing flies. Adding to triple list.'])
            end
            triple_interact_flies = [triple_interact_flies,this_fly];
%             who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
            continue
        elseif isempty(suspected_flies)
            disp(['only one suspected fly expected. However I found nothing. Droping this: ',num2str(this_fly)])
            who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
            who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = []; 
            continue
        elseif length(suspected_flies)>2
            if f.ft_debug
                disp(['only one suspected fly expected. However I found more than two: ',mat2str(suspected_flies)])
                disp('Adding to tripled list.')
            end
            triple_interact_flies = [triple_interact_flies,this_fly];
%             who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
            continue
        end
            
        % reset assignations of these flies
        f = resetAssignationsofTheseObjects(f,this_fly);
        
        % do the surface assignements, and flies in to the interaction list
        % to be resolved by resolveInteractingObjects
        f = assignInteractionSurface1(f,this_fly,suspected_flies);
        
        % if these flies are in missing flies list clear them
        who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
        who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
        
    end
end

% similarly in can be done with three colliders
% colliding or overpassing with two object
suspected_merged_objects = logical(delta_area > f.tripled_fly_area_ratio);
reset_these_flies = f.current_object_status(suspected_merged_objects);
% combine from previous double interaction search
reset_these_flies = [reset_these_flies,triple_interact_flies];
 

if ~isempty(reset_these_flies)
    % reset assignations of these flies
    f = resetAssignationsofTheseObjects(f,reset_these_flies);

    % mark the objects as suspected of being merged objects
    for i = 1:length(reset_these_flies)
        
        this_fly = reset_these_flies(i);
        this_object = f.current_objects(f.current_object_status==this_fly);
        
        if isIntheCollignoreZone(f,this_object.Centroid)
        % just ignore all collisions if the object is close to the
        % boundary. it becomes very complicated to resolve collisions when
        % flies are about to enter or exit. change the boundary size and
        % experiment the effect: edge_coll_ignore_dist
            continue
            
        else
            % fact check, there should be two suspected flies
            suspected_flies = findSuspectedInteractingFlies(f,this_fly)';
            prev_ints = getInteractions(f,[this_fly,suspected_flies]);
            % get flies close to given fly, get 9 closest ones
            closer_flies = findClosestFlies(f,this_fly,9);
            % remove the ones far away
            closer_flies(closer_flies(:,2)>f.close_fly_distance,:) = [];
            % get only the close interactions
            prev_ints = intersect(prev_ints,closer_flies(:,1)');
           
            suspected_flies = unique([suspected_flies,prev_ints]);
            
            
            if ~isempty(suspected_flies)
                % remove existing flies
                suspected_flies(logical(sum(suspected_flies==f.current_object_status,1))) = [];
                suspected_flies(suspected_flies==this_fly) = [];
                suspected_flies(logical(sum(suspected_flies==who_is_handled_so_far,1))) = [];
            end
            
            if length(suspected_flies)==1
                % may be this is a double fly
                f = assignInteractionSurface1(f,this_fly,suspected_flies);
                % if these flies are in missing flies list clear them
                if ~isempty(who_misses_currently)
                    who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                    who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
                end
                
                if f.ft_debug
                    disp(['two suspected fly expected. However I found one: ',mat2str(suspected_flies),' Assigning it to doubled flies'])
                end
                continue
            elseif (length(suspected_flies)>2)
                if f.ft_debug
                    disp(['two suspected fly expected. However I found these: ',mat2str(suspected_flies),' Will still try to resolve'])
                end
            elseif isempty(suspected_flies)
                disp(['only one suspected fly expected. However I found nothing. Droping this: ',num2str(this_fly)])
                who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = []; 
                continue

            end
            
            % reset assignations of these flies
            f = resetAssignationsofTheseObjects(f,this_fly);
            
            % assign surfaces and add to the interaction list
            f = assignInteractionSurface2(f,this_fly,suspected_flies);
            
            % remove from missing list
            who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
            who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
            
        end
    end
end

%% totally overlapped flies
% if a fly is totally under another fly than there will be missing fly but
% not a large objects
go_on = 0;
% go over the remaining missing list and make necessary assignments
if ~isempty(who_misses_currently)
    cnt = 1;
    for i = 1:length(who_misses_currently)
        xy = [f.tracking_info.x(who_misses_currently(cnt),f.current_frame),...
        f.tracking_info.y(who_misses_currently(cnt),f.current_frame)];
        if isIntheCollignoreZone(f,xy)
            who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(cnt)];
            who_misses_currently(cnt) = [];
        else
            cnt = cnt + 1;
        end
    end
        
    
end
if ~isempty(who_misses_currently)
    go_on = 1;
end

while go_on
    % if the fly is in the periferi ignore
    xy = [f.tracking_info.x(who_misses_currently(1),f.current_frame),...
        f.tracking_info.y(who_misses_currently(1),f.current_frame)];
    if isIntheCollignoreZone(f,xy)
        % just ignore all collisions if the object is close to the
        % boundary. it becomes very complicated to resolve collisions when
        % flies are about to enter or exit. change the boundary size and
        % experiment the effect: edge_coll_ignore_dist
        who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(cnt)];
        who_misses_currently(1) = [];
        if isempty(who_misses_currently)
            go_on = 0;
        end
    else
        % in the main arena. find out the suspected flies
        this_fly = who_misses_currently(1);
        
        % ONLY GETS THE INTERACTIONS OF MISSING FLIES. dO WE NEED TO GET
        % THE INTERACTION OF THE INTERACTING GUYS?

        % was it interacting previously with another fly
        interacts_with = getInteractions(f,this_fly);
        % get flies close to given fly, get 9 closest ones
        closer_flies = findClosestFlies(f,this_fly,9);
        % remove the ones far away
        closer_flies(closer_flies(:,2)>f.close_fly_distance,:) = [];
        % remove existing flies
        if ~isempty(interacts_with)
%             interacts_with(logical(sum(interacts_with==f.current_object_status,1))) = [];
            interacts_with(interacts_with==this_fly) = [];
        end
        
        % must ve intersecting with these
        % get the matching guys
        suspected_flies = intersect(interacts_with,closer_flies(:,1)');
        if ~isempty(suspected_flies)
            suspected_flies(logical(sum(suspected_flies==who_is_handled_so_far,1))) = []; 
        end
        
        % now sort these
        if isempty(suspected_flies)
            if f.ft_debug
                disp(['fly: ',num2str(this_fly),' is lost and it was not interacting previously. Area smaller, or exited?'])
            end
            who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(1)];
            who_misses_currently(1) = [];
            if isempty(who_misses_currently)
                go_on = 0;
            end 
        else
            % how many suspected are there
            switch length(suspected_flies)
                case 1
                    
                    existing_susp_flies = suspected_flies(logical(sum(suspected_flies==f.current_object_status,1)));
                    
                    if isempty(existing_susp_flies)
                        % there is not an object to work on. All flies are
                        % missing. Simply drop all
                        if f.ft_debug
                            disp(['These: ',mat2str([this_fly,suspected_flies]),' are all missing. Dropping all of them.'])
                        end
                        who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                        who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
                        if isempty(who_misses_currently)
                            go_on = 0;
                        end 
                        continue
                    
                    else

                        % either collides or overpasses
                        % set the objects status to negative of itself
                        f.current_object_status(f.current_object_status==suspected_flies) = -f.current_object_status(f.current_object_status==suspected_flies);
                        % do the surface assignements, and flies in to the interaction list
                        % to be resolved by resolveInteractingObjects
                        f = assignInteractionSurface1(f,suspected_flies,this_fly);

                        % if these flies are in missing flies list clear them
                        who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                        who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
                        if f.ft_debug
                            disp(['fly: ',num2str(this_fly),' is missing but there is not a large object. Might have totally overlapped'])
                        end
                    end
                    
                case 2
                    % there are both colliders and overpassers
                    % assign surfaces and add to the interaction list
                    
                    % here there are three flies interacting. we know that
                    % this_fly is missing, what about others. If one of
                    % them is also missing than use the existing fly as the
                    % existing objects. Find which one is in the current
                    % object status
                    
                    existing_susp_flies = suspected_flies(logical(sum(suspected_flies==f.current_object_status,1)));
                    
                    if isempty(existing_susp_flies)
                        % there is not an object to work on. All flies are
                        % missing. Simply drop all
                        if f.ft_debug
                            disp(['These: ',mat2str([this_fly,suspected_flies]),' are all missing. Dropping all of them.'])
                        end
                        who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                        who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
                        if isempty(who_misses_currently)
                            go_on = 0;
                        end
                        continue
                    elseif length(existing_susp_flies)==1
                        % this is good. two flies are missing and one
                        % existing object. That means all two misssing are
                        % under this guy.
                        suspected_flies(suspected_flies==existing_susp_flies(1)) = this_fly;
                        this_fly = existing_susp_flies(1);
                        % set object identity to negative
                        f.current_object_status(f.current_object_status==this_fly) = -f.current_object_status(f.current_object_status==this_fly);
                    elseif length(existing_susp_flies)==2
                        % this does not make sense. One fly missing and all
                        % other previously interacting gusy exist. get only
                        % the closest guy
                        
                        suspected_flies = this_fly;
                        this_fly = existing_susp_flies(existing_susp_flies==closer_flies(1,1));
%                         suspected_flies(suspected_flies==existing_susp_flies(1)) = this_fly;
%                         suspected_flies(2) = [];
                        % set object identity to negative
                        f.current_object_status(f.current_object_status==this_fly) = -f.current_object_status(f.current_object_status==this_fly);
                        
                    end
                    
                    f = assignInteractionSurface2(f,this_fly,suspected_flies);
                    if f.ft_debug
                        disp(['fly: ',num2str(this_fly),' is missing but there is not a large object. Might have totally overlapped'])
                    end
                    % if these flies are in missing flies list clear them
                    who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                    who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
                case 3

                    %%
                    if f.ft_debug
                        disp(['fly: ',num2str(this_fly),' is missing but there is not a large object.'])
                        disp('It seems to interact with other 3 missing flies.')
                        disp('I did not anticipate this. You need to code for this')
                        disp('loosing them for now')
                    end
                    who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                    who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
            end
            if length(suspected_flies)>3
                if f.ft_debug
                    disp(['fly: ',num2str(this_fly),' is missing but there is not a large object.'])
                    disp(['It seems to interact with other ',num2str(length(suspected_flies)),' missing flies: ',mat2str(suspected_flies)])
                    disp('I did not anticipate this. You need to code for this')
                    disp('loosing them for now')
                end
                who_is_handled_so_far = [who_is_handled_so_far;who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2)))];
                who_misses_currently(logical(sum(who_misses_currently==[this_fly,suspected_flies],2))) = [];
            end
                
            if isempty(who_misses_currently)
                go_on = 0;
            end
                    
            
        
        end
    end
end

%put the list in order, remove duplicates, merge multi separated
%interactions

f = putInteractListinOrder(f);

    
    
    
    
    
    
    
    