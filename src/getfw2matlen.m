function [totlen,nofflies,noftracks] = getfw2matlen(filepath)
% sums up all the trajectory lengths

% try loading the vtracks

% try
    datatemp = load([filepath(1:end-4),'.flywalk'],'-mat');
    f = datatemp.fly_walk_obj;
    clear datatemp
    nofflies = mode(sum(f.tracking_info.fly_status==1,1));
    noftracks = find(f.tracking_info.fly_status(:,end)~=0,1,'last');
    % start constructing the variable matrix
    % determine the size of the matrix
    totlen  = 0;
    for i = 1:noftracks
       totlen  = totlen + find(f.tracking_info.fly_status(i,:)==1,1,'last')-find(f.tracking_info.fly_status(i,:)==1,1);
    end
