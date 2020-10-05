function valout = GetValExpMat(expmat,colnum,expind,trialind)

%GetValExpMat
% GetValExpMat(expmat) retuns a vector which contains the number of flies
% in each experimental replicate in the expmat
%
% GetValExpMat(expmat,25) returns the list of number of days that flies
% were starved
%
% GetValExpMat(expmat,27,1,3) returns the value for the room temperature
% for the experiment# 1 and trail# 3
%
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24,starve_day-25,age_day-26,room_Temp-27,room_Hum-28, fileindex-29};
%

switch nargin
    case 3
        trialind = 'all';
    case 2
        trialind = 'all';
        expind = 'all';
    case 1
        trialind = 'all';
        expind = 'all';
        colnum = 24;
end


% what mode is requested
if strcmp(expind,'all') % get all experiments and all trials
    % how may experiments are there?
    elist = unique(expmat(:,2))';
else
    elist = expind;
end

ntrl = 0; % total number of trials to be returned

for i = elist
    % get indices
    eind = expmat(:,2)==i;

    % find trials
    if strcmp(trialind,'all')
        ntrl = ntrl + numel((unique(expmat(eind,3)))');    
    else
        ntrl = ntrl + numel(trialind);
    end
end
    
valout = zeros(ntrl,1); % no flies for now
    

    
% go over experimets and find trials
cnt = 1;
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
        valout(cnt) = expmat(eind(tind(1)),colnum);
        cnt = cnt + 1;
    end
end
        