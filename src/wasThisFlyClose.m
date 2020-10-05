function status = wasThisFlyClose(f,this_fly,xy)


poslit = [f.tracking_info.x(this_fly,f.current_frame-1),...
    f.tracking_info.y(this_fly,f.current_frame-1)];

% get the euclidian-distance matrix
% distance matrix
D = pdist2(poslit,xy);

% taking the jump length as criteria. the current value jump_length: 9 is
% almost identical the mean minor axis length. it might be chenged to
% another parameter

status = D<=f.jump_length;