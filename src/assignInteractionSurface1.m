function f = assignInteractionSurface1(f,this_fly,suspected_flies)
% figures out the on which surface the interacring flies are and assigns
% the tracking info, objects info and interaction list

if f.reflection_status(this_fly,f.current_frame-1)==f.reflection_status(suspected_flies,f.current_frame-1)
    % same surface
%     f.current_object_status(f.current_object_status==this_fly) = -1;
    % add to the interaction list. signs must be same. fact check later
    interactors = [getFlySurface(f,this_fly),getFlySurface(f,suspected_flies)];
    f.interaction_list = [f.interaction_list,{interactors}];
    % add to the fly collision history
    f = setColl(f,this_fly,abs(suspected_flies));
    if f.ft_debug
        disp(['suspected interactions: ',mat2str(interactors)])
    end
else
    % walking on opposite surfaces
%     f.current_object_status(f.current_object_status==this_fly) = -11;
    % register in to the list
    interactors = [getFlySurface(f,this_fly),getFlySurface(f,suspected_flies)];
    f.interaction_list = [f.interaction_list,{interactors}];
    % add to the overpassing history
    f = setOver(f,this_fly,abs(suspected_flies));
    if f.ft_debug
        disp(['suspected interactions: ',mat2str(interactors)])
    end
end

% % add these flies to all crwod list for future curation purposes
% f.crowd_interaction_list = [f.crowd_interaction_list,{[f.current_frame,interactors]}];

f = add2CrowdIntList(f,interactors);