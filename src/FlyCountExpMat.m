function nf = FlyCountExpMat(expmat,expind,trialind)


% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 fileindex-25};

switch nargin
    case 2
        trialind = 'all';
    case 1
        trialind = 'all';
        expind = 'all';
end


% what mode is requested
if strcmp(expind,'all') % get all experiments and all trials
    % how may experiments are there?
    elist = unique(expmat(:,2))';
else
    elist = expind;
end

    
nf = 0; % no flies for now
    

    
% go over experimets and find trials
for i = elist
    % get indices
    eind = find(expmat(:,2)==i);

    % find trials
    if strcmp(trialind,'all')
        trials = (unique(expmat(eind,3)))';
    else
        trials = trialind;
    end

    % go over trials and count flies
    for ti = trials
        tind = find(expmat(eind,3)==ti);
        nf = nf + expmat(eind(tind(1)),24);
    end
end
        