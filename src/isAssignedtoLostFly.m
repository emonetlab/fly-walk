function [to_this_fly,is_in_the_periphery] = isAssignedtoLostFly(f,xy)

% find which flies were lost and gone in the previous frame
flies_lost_in_last_frame = [find(f.tracking_info.fly_status(:,f.current_frame-1)==2);...
    find(f.tracking_info.fly_status(:,f.current_frame-1) == 3)];

to_this_fly = [];
is_in_the_periphery = isInthePeriferi(f,xy);
if isempty(flies_lost_in_last_frame)
    return;
end

poslit = [f.tracking_info.x(flies_lost_in_last_frame,f.current_frame-1),...
    f.tracking_info.y(flies_lost_in_last_frame,f.current_frame-1)];

% get the euclidian-distance matrix
% distance matrix
D = pdist2(poslit,xy);

% taking the jump length as criteria. the current value jump_length: 9 is
% almost identical the mean minor axis length. it might be chenged to
% another parameter
% if min(D)<=f.jump_length
if min(D)<=nanmean(nanmean(f.tracking_info.majax(flies_lost_in_last_frame,1:f.current_frame)))
    % one fly is assigned to a lost fly in the perifery
    % verify that restrict to that case
    to_this_fly = flies_lost_in_last_frame(D==min(D));
end