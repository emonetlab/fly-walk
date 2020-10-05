function suspected_flies = findSuspectedInteractingFlies(f,this_fly)
%findSuspectedInteractingFlies finds the missing flies and checks if they 
% were close to this fly in the previous frames, more than close_fly_distance
% tracking infor is used for calculations

who_misses_currently = find(f.tracking_info.fly_status(:,f.current_frame)==2);

% remove the given fly
who_misses_currently(who_misses_currently==this_fly) = [];

% may be the flies just exited remove them
who_misses_currently(isFlyInthePeriferi(f,who_misses_currently)) = [];

% get flies close to given fly
closer_flies = findClosestObjects(f,this_fly,length(who_misses_currently));

% remove the ones far away
closer_flies(closer_flies(:,2)>f.close_fly_distance,:) = [];

% get the matching guys
suspected_flies = intersect(closer_flies(:,1),who_misses_currently);
