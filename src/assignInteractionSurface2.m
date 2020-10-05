function f = assignInteractionSurface2(f,this_fly,suspected_flies)
% the surface assignement code for triple interacting flies
% deterrmines on which surface flies are walking and makes necessary
% assignements
%

% add to the interaction list
interactors = [getFlySurface(f,this_fly),getFlySurface(f,suspected_flies)];
f.interaction_list = [f.interaction_list,{interactors}];
% add to collision history
f = setColl(f,this_fly,abs(suspected_flies(sign(interactors(1))==sign(getFlySurface(f,suspected_flies)))));
% add to overlap history
f = setOver(f,this_fly,abs(suspected_flies(sign(interactors(1))~=sign(getFlySurface(f,suspected_flies)))));
if f.ft_debug
    disp(['suspected interactions: ',mat2str(interactors)])
end


% % add these flies to all crwod list for future curation purposes
% f.crowd_interaction_list = [f.crowd_interaction_list,{[f.current_frame,interactors]}];

f = add2CrowdIntList(f,interactors);
