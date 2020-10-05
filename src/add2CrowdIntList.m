function f = add2CrowdIntList(f,interactors)

interactors = sort(abs(interactors));
assigned = 0;
if isempty(f.crowd_interaction_list)
    f.crowd_interaction_list(1) = {[f.current_frame,sort(abs(interactors))]};
    assigned = 1;
else
    
    % go over the list and try to find a match
    for i = 1:numel(f.crowd_interaction_list)
        cinl = f.crowd_interaction_list{i};
       
        if isequal(intersect(cinl,[f.current_frame,interactors]),[f.current_frame,interactors])
            return
        elseif f.current_frame-cinl(end,1)>1
            continue
        else
            same_flies = intersect(interactors,cinl(:,2:end));
            if length(same_flies)>=(length(interactors)-1)
                % insert at the end of this list
                if length(interactors)>(size(cinl,2)-1)
                    ext_n = length(interactors)-(size(cinl,2)-1);
                    cinl(end+1,end+ext_n) = 0;
                    
                else
                    cinl(end+1,:) = 0;
                end
                cinl(end,1:length(interactors)+1) = [f.current_frame,interactors];
                f.crowd_interaction_list(i) = {cinl};
                assigned = 1;
            end
        end
    end
end
    
% if not assigned, assign it to a new element
if ~assigned
     f.crowd_interaction_list(end+1) = {[f.current_frame,sort(abs(interactors))]};
end

                