function jumping_flies = findJumpingFlies(f)
%findJumpingFlies finds flies whose speed if above the jumping threshold
speed_mat = sqrt(diff(f.tracking_info.x(:,f.current_frame-1:f.current_frame)...
    ,1,2).^2+diff(f.tracking_info.y(:,f.current_frame-1:f.current_frame),1,2).^2);
jumping_flies = find(speed_mat>=f.jump_length);