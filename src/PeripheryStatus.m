function f = PeripheryStatus(f)
% checks if flies are in the periphery and save it in
% tracking_info.periphery for current_frame

% get zone edges
if f.apply_mask
    bxl = f.ExpParam.source.x + f.dist_fly_edge_leave;
    bxr = size(f.current_raw_frame,2)-f.ExpParam.crop_box.rcrp-f.dist_fly_edge_leave;
    byt = f.ExpParam.crop_box.tcrp+f.dist_fly_edge_leave;
    byb = size(f.current_raw_frame,1)-f.ExpParam.crop_box.bcrp-f.dist_fly_edge_leave;
else
    bxl = f.ExpParam.source.x + f.dist_fly_edge_leave;
    bxr = size(f.current_raw_frame,2)-f.dist_fly_edge_leave;
    byt = 1+f.dist_fly_edge_leave;
    byb = size(f.current_raw_frame,1)-f.dist_fly_edge_leave;
end

xy = [f.tracking_info.x(:,f.current_frame),f.tracking_info.y(:,f.current_frame)];
criteria = [xy(:,1)<=bxl,xy(:,1)>=bxr,xy(:,2)>=byb,xy(:,2)<=byt];
f.tracking_info.periphery(:,f.current_frame) = any(criteria,2);

