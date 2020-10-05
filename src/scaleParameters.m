function f = scaleParameters(f)

% rescales all the parameters with the calibration value and fps

 f.maximum_distance_to_link_trajectories = f.maximum_distance_to_link_trajectories/f.ExpParam.fps/f.ExpParam.mm_per_px;
 
 f.min_fly_area = round(f.min_fly_area/(f.ExpParam.mm_per_px).^2);
 
 f.dist_fly_edge_leave = f.dist_fly_edge_leave/f.ExpParam.mm_per_px;
 
 f.center_zone_edge = f.center_zone_edge/f.ExpParam.mm_per_px;
 
 f.immobile_speed = f.immobile_speed/f.ExpParam.fps/f.ExpParam.mm_per_px;
 
 f.jump_length = f.jump_length/f.ExpParam.fps/f.ExpParam.mm_per_px;
 
 f.jump_length_split = f.jump_length_split/f.ExpParam.fps/f.ExpParam.mm_per_px;
 
 f.close_to_wall_dist = f.close_to_wall_dist/f.ExpParam.mm_per_px;
 
 f.edge_coll_ignore_dist = f.edge_coll_ignore_dist/f.ExpParam.mm_per_px;
 
 f.close_fly_distance = f.close_fly_distance/f.ExpParam.mm_per_px;
 
 f.trajectory_vis_length = round(f.trajectory_vis_length*f.ExpParam.fps);

 