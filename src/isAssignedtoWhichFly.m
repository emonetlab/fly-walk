function to_this_fly = isAssignedtoWhichFly(f,xy)

% find which flies were lost and gone in the previous frame
flies_ok_in_last_frame = find(f.tracking_info.fly_status(:,f.current_frame-1)==1);

poslit = [f.tracking_info.x(flies_ok_in_last_frame,f.current_frame-1),...
    f.tracking_info.y(flies_ok_in_last_frame,f.current_frame-1)];

% get the euclidian-distance matrix
% distance matrix
D = pdist2(poslit,xy);

% taking the jump length as criteri. the current value jump_length: 9 is
% almost identical the mean minor axis length. it might be chenged to
% another parameter
to_this_fly = [];
if min(D)<=f.jump_length
    % one fly is assigned to a lost fly in the perifery
    % verify that restrict to that case
    to_this_fly = flies_ok_in_last_frame(D==min(D));
end