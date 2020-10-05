%f = findSuspectedInteractions(f)
% returs all suspected and reguistered interactions in the given frame.
% Default current frame
%
function [suspInt,CurrInt] = findSuspectedInteractions(f,framenum)

if nargin==1
    framenum = f.current_frame;
end

% get the list of missing flies
who_misses_currently = find(f.tracking_info.fly_status(:,framenum)==2);
% may be the flies just exited remove them
who_misses_currently(isFlyInthePeriferi(f,who_misses_currently)) = [];

CurrInt = getAllInteractions(f,framenum);

% start suspected interactions, probably the ones in the collision ignore
% zone
suspInt = [];

if isempty(who_misses_currently)
    return
end

%go over all missing flies and assign them to closest existing flies for
%resolution

go_on = 1;
% go over the remaining missing list and make necessary assignments

while go_on

        % find out the suspected flies
        missing_fly = who_misses_currently(1);
        
        
        % whos is the closest current object
        % output is the fly number not objects number. get it from
        % current_object_status
        if f.tracking_info.jump_status(missing_fly,framenum)
            ObjectsNDistance = abs(findClosestCurrentObjects2ThisFly(f,missing_fly,15,framenum));
            if ~isempty(ObjectsNDistance)
                ObjectsNDistance(ObjectsNDistance(:,2)>(3*f.close_fly_distance),:) = [];   % delete flies far away
            end
        else
            ObjectsNDistance = abs(findClosestCurrentObjects2ThisFly(f,missing_fly,3,framenum));
            if ~isempty(ObjectsNDistance)
                ObjectsNDistance(ObjectsNDistance(:,2)>f.close_fly_distance,:) = [];   % delete flies far away
            end
        end
        
        if ~isempty(ObjectsNDistance)
            % delete objects with zero index as well
            if any(ObjectsNDistance(:,1)==0)
                if f.ft_debug
                    disp(['This missing fly: ',mat2str(missing_fly),' appears to be close an unassigned object. Might be important to check'])
                    f.tracking_info.error_code(missing_fly,framenum)=3;
                end
            end
            ObjectsNDistance(ObjectsNDistance(:,1)==0,:) = [];
        end
        
        if isempty(ObjectsNDistance)
            if f.ft_debug
                disp(['These: ',mat2str(missing_fly),' is missing in the middle of nowhere. Dropping this.'])
            end
            f.tracking_info.error_code(missing_fly,framenum) = 2;
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
            Prev_Area = f.tracking_info.area(this_near_object,framenum-1);
            if isnan(Prev_Area)
                % get the meadian area of other flies
                Prev_Area = median(f.tracking_info.area(~isnan(f.tracking_info.area(:,framenum-1)),framenum-1));
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
            was_interacting_with = wasThisFlyInteracting(f,missing_fly,framenum);
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
            was_interacting_with = wasThisFlyInteracting(f,missing_fly,framenum);
            
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
%             % reset large object assignations
%             f = resetAssignationsofTheseObjects(f,existing_object);
        end
        
        % if these flies are in missing flies list clear them
        who_misses_currently(who_misses_currently==missing_fly) = [];
        if isempty(who_misses_currently)
            go_on = 0;
        end 
        suspInt = [suspInt;[missing_fly,existing_object]];
%         f  = HandleMergeAssignment(f,missing_fly,existing_object);
        
end
% 
% % if there are too many flies in the interaction remove them
% f = clearMultiInteractions(f);
%                     
% % assign all interaction to crowd list
% if ~isempty(f.interaction_list)
%     for i = 1:numel(f.interaction_list)
%         interactors = f.interaction_list{i};
%         f = add2CrowdIntList(f,interactors);
%     end
% end



    
    
    
    
    
    
    
    