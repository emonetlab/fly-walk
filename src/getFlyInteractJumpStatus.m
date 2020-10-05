function status = getFlyInteractJumpStatus(f,this_fly)

status = [f.tracking_info.jump_status(this_fly,f.current_frame)==1;...
    ~isnan(f.tracking_info.collision(this_fly,f.current_frame));...
    ~isnan(f.tracking_info.overpassing(this_fly,f.current_frame));...
    f.tracking_info.periphery(this_fly,f.current_frame)==1];
status = any(status);