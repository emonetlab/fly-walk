function f= clearMultiInteractions(f)
% drops the interactions if there are more than given number of flies
% interacting

if isempty(f.interaction_list)
    return
else
    int_ind = 1;
    for i = 1:numel(f.interaction_list)
        if length(f.interaction_list{int_ind})>f.max_num_of_interacting_flies
            interactors = f.interaction_list{int_ind};
            existing_object = abs(f.interaction_list{int_ind}(1));
            suspected_fly  = abs(f.interaction_list{int_ind}(2:end));
            % reset collision and overpassings
            f = reSetColl(f,existing_object,abs(suspected_fly(sign(interactors(1))==sign(getFlySurface(f,abs(suspected_fly))))));
            % add to overlap history
            f = reSetOver(f,existing_object,abs(suspected_fly(sign(interactors(1))~=sign(getFlySurface(f,abs(suspected_fly))))));
            
            if f.ft_debug
                disp(['too many interactors, ignoring all: ',mat2str(f.interaction_list{int_ind})])
            end
            f.interaction_list(int_ind) = [];
        else
            int_ind = int_ind + 1;
        end
    end
end