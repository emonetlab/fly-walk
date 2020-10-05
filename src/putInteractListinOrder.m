function f = putInteractListinOrder(f)

if isempty(f.interaction_list)
    return
end

% % delete the part in the whole crowd interactions
% f.crowd_interaction_list(end-numel(f.interaction_list)+1:end) = [];

main_flies = zeros(numel(f.interaction_list),1);

% get the main flies
for i = 1:numel(f.interaction_list)
    main_flies(i) = f.interaction_list{i}(1);
end

[unique_flies,~,ind_uf] = unique(main_flies);

% make a new list
 intln = cell(1,length(unique_flies));
%  cintln = cell(1,length(unique_flies));
 
 for i = 1:length(unique_flies)
     tempfl = [];
     for j=find(ind_uf==i)'
         tempfl = [tempfl,f.interaction_list{j}(2:end)];
     end
     tempfl = unique(tempfl);
     intln(i) = {[unique_flies(i),tempfl]};
%      cintln(i) = {[f.current_frame,unique_flies(i),tempfl]};
 end
 
 % assign the list 
 f.interaction_list = intln;
%  f.crowd_interaction_list = [f.crowd_interaction_list,cintln];
     