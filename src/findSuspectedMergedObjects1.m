%% f = findSuspectedMergedObjects(f);
% finds objects that are suspiciously large compared to the fly area in the last frame
% this does not care about double or triple flies just finds missing flies
% and assigns to the closest fly
%
function f = findSuspectedMergedObjects1(f)

% get the list of missing flies
who_misses_currently = find(f.tracking_info.fly_status(:,f.current_frame)==2);
% may be the flies just exited remove them
who_misses_currently(isFlyInthePeriferi(f,who_misses_currently)) = [];
if isempty(who_misses_currently)
    return
end

%go over all missing flies and assign them to closest existing flies for
%resolution

go_on = 0;
% go over the remaining missing list and make necessary assignments

% % remove the ones in the collision ignore zone
% if ~isempty(who_misses_currently)
%     cnt = 1;
%     for i = 1:length(who_misses_currently)
%         xy = [f.tracking_info.x(who_misses_currently(cnt),f.current_frame),...
%         f.tracking_info.y(who_misses_currently(cnt),f.current_frame)];
%         if isIntheCollignoreZone(f,xy)
%             who_misses_currently(cnt) = [];
%         else
%             cnt = cnt + 1;
%         end
%     end  
% end
% 
if ~isempty(who_misses_currently)
    go_on = 1;
end

while go_on

        % in the main arena. find out the suspected flies
        missing_fly = who_misses_currently(1);
        
        
        % whos is the closest current object
        % output is the fly number not objects number. get it from
        % current_object_status
        if f.tracking_info.jump_status(missing_fly,f.current_frame)
            ObjectsNDistance = abs(findClosestCurrentObjects2ThisFly(f,missing_fly,15));
            ObjectsNDistance(ObjectsNDistance(:,2)>(3*f.close_fly_distance),:) = [];   % delete flies far away
        else
            ObjectsNDistance = abs(findClosestCurrentObjects2ThisFly(f,missing_fly,3));
            ObjectsNDistance(ObjectsNDistance(:,2)>f.close_fly_distance,:) = [];   % delete flies far away
        end
        
        
        % delete objects with zero index as well
        if any(ObjectsNDistance(:,1)==0)
            if f.ft_debug
                disp(['This missing fly: ',mat2str(missing_fly),' appears to be close an unassigned object. Might be important to check'])
                f.tracking_info.error_code(missing_fly,f.current_frame)=3;
            end
        end
        ObjectsNDistance(ObjectsNDistance(:,1)==0,:) = [];        
        
        if isempty(ObjectsNDistance)
            if f.ft_debug
                disp(['These: ',mat2str(missing_fly),' is missing in the middle of nowhere. Dropping this.'])
            end
            f.tracking_info.error_code(missing_fly,f.current_frame) = 2;
            who_misses_currently(who_misses_currently==missing_fly) = [];
            if isempty(who_misses_currently)
                go_on = 0;
            end 
            continue
        end
        
        % are there large objects among these
        
        Delta_Area = zeros(size(ObjectsNDistance,1),1);
        
        for near_object_ind = 1:size(ObjectsNDistance,1)
            
            this_near_object = ObjectsNDistance(near_object_ind,1);
            Prev_Area = f.tracking_info.area(this_near_object,f.current_frame-1);
            if isnan(Prev_Area)
                % get the meadian area of other flies
                Prev_Area = median(f.tracking_info.area(~isnan(f.tracking_info.area(:,f.current_frame-1)),f.current_frame-1));
                if f.ft_debug
                    disp(['fly: ',num2str(this_near_object),' seems to be assigned now. I will use median area off other flies instead.'])
                end
            end
            Delta_Area(near_object_ind) = f.current_objects(abs(f.current_object_status)==this_near_object).Area/Prev_Area;
        end
        
        % find which of these close ones has larger area
        existing_object = ObjectsNDistance(find(Delta_Area>f.doubled_fly_area_ratio,1),1);
        
        if isempty(existing_object)
            % none of these are large. get the closest guy as totally
            % overlapping
            was_interacting_with = wasThisFlyInteracting(f,missing_fly);
            if ~isempty(was_interacting_with)
                found_interacting = 0;
                for kk=1:size(ObjectsNDistance,1)
                    if any(was_interacting_with==ObjectsNDistance(kk,1))
                        existing_object = ObjectsNDistance(kk,1);
                        if f.ft_debug
                            disp(['fly: ',num2str(missing_fly),' is missing. No large object. Found this previously interacting fly close by: ',num2str(existing_object)])
                        end
                        found_interacting = 1;
                    end
                end

                if ~found_interacting
                    existing_object = ObjectsNDistance(1);
                    if f.ft_debug
                            disp(['fly: ',num2str(missing_fly),' is missing. No large object. None of the interacting flies are around. Linking to closest fly : ',num2str(existing_object)])
                    end
                end
            else
                existing_object = ObjectsNDistance(1);
                if f.ft_debug
                        disp(['fly: ',num2str(missing_fly),' is missing. No large object. No previously interacting fly. Linking to closest fly : ',num2str(existing_object)])
                end
            end
             
            % either collides or overpasses
            % set the objects status to negative of itself
            f.current_object_status(abs(f.current_object_status)==existing_object) = -abs(f.current_object_status(abs(f.current_object_status)==existing_object));
 
            if f.ft_debug
                disp(['fly: ',num2str(missing_fly),' is missing but there is not a large object. Might have totally overlapped with: ',num2str(existing_object)])
            end
        else
            % was it interacting with the first one. Than assign to the
            % first one.
            was_interacting_with = wasThisFlyInteracting(f,missing_fly);
            
            if ~isempty(was_interacting_with)
                if (~any(was_interacting_with==existing_object))
                    for kk=1:size(ObjectsNDistance,1)
                        if any(was_interacting_with==ObjectsNDistance(kk,1))
                            existing_object = ObjectsNDistance(kk,1);
                            if f.ft_debug
                                disp(['fly: ',num2str(missing_fly),' is missing. No large object. Found this previously interacting fly close by: ',num2str(existing_object)])
                            end
                        end
                    end
                end
            end
                        
            
            if f.ft_debug&&(existing_object==ObjectsNDistance(find(Delta_Area>f.doubled_fly_area_ratio,1),1))
                disp(['fly: ',num2str(missing_fly),' is missing and a large object found close by: ',num2str(existing_object)])
            end
            % reset large object assignations
            f = resetAssignationsofTheseObjects(f,existing_object);
        end
        
        % if these flies are in missing flies list clear them
        who_misses_currently(who_misses_currently==missing_fly) = [];
        if isempty(who_misses_currently)
            go_on = 0;
        end 
        
        f  = HandleMergeAssignment(f,missing_fly,existing_object);
        
end

% if there are too many flies in the interaction remove them
f = clearMultiInteractions(f);
                    
% assign all interaction to crowd list
if ~isempty(f.interaction_list)
    for i = 1:numel(f.interaction_list)
        interactors = f.interaction_list{i};
        f = add2CrowdIntList(f,interactors);
    end
end


%put the list in order, remove duplicates, merge multi separated
%interactions
% 
% f = putInteractListinOrder(f);

% remove collision ignore zone flies from the interaction list
% remove the ones in the collision ignore zone
removethis = zeros(numel(f.interaction_list),1);
for i = 1:numel(f.interaction_list)
    this_interaction = abs(f.interaction_list{i});
    xy = [f.tracking_info.x(this_interaction,f.current_frame),...
    f.tracking_info.y(this_interaction,f.current_frame)];
    CIZStatus = isIntheCollignoreZone(f,xy);
    if any(CIZStatus)
        removethis(i) = 1;
    end
end  
f.interaction_list(logical(removethis)) = [];

    
    
    
    
    
    
    
    