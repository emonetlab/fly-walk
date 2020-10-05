function f= HandleMergeAssignment(f,missing_fly,existing_object)

% find if this guy was assigned before
assigned = 0;
if isempty(f.interaction_list)
    interactors = [getFlySurface(f,existing_object),getFlySurface(f,missing_fly)];
    f.interaction_list(1) = {interactors};
    suspected_fly = missing_fly;
    if f.ft_debug
        disp(['suspected interactions: ',mat2str(interactors)])
    end
else
    for i = 1:numel(f.interaction_list)
        inl = f.interaction_list{i};
        if abs(inl(1))==existing_object
            f.interaction_list(i) = {[inl,getFlySurface(f,missing_fly)]};
            assigned = 1;
            suspected_fly = [abs(inl(2:end)),missing_fly];
            interactors = ([inl,getFlySurface(f,missing_fly)]);
%             if length(interactors)>f.max_num_of_interacting_flies
%                 if f.ft_debug
%                     disp(['too many interactors, ignoring all: ',mat2str(interactors)])
%                 end
%                 interactors = [];
%             else
                if f.ft_debug
                    disp(['suspected interactions (appended): ',mat2str(interactors)])
                end
%             end
        end
    end
    
    % if not assigned, assign to new interaction
    if ~assigned
        interactors = [getFlySurface(f,existing_object),getFlySurface(f,missing_fly)];
        f.interaction_list(numel(f.interaction_list)+1) = {interactors};
        suspected_fly = missing_fly;
        if f.ft_debug
            disp(['suspected interactions: ',mat2str(interactors)])
        end
    end
end
if ~isempty(interactors)
    f = setColl(f,existing_object,abs(suspected_fly(sign(interactors(1))==sign(getFlySurface(f,suspected_fly)))));
    % add to overlap history
    f = setOver(f,existing_object,abs(suspected_fly(sign(interactors(1))~=sign(getFlySurface(f,suspected_fly)))));
end