function f = getPeripheryStatus(f)
% checks if flies are in the periphery and save it in
% tracking_info.periphery

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


f.tracking_info.periphery = zeros(size(f.tracking_info.signal));
tot_num_of_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');


for i = 1:tot_num_of_flies
    xy = [f.tracking_info.x(i,:)',f.tracking_info.y(i,:)']; 
    criteria = [xy(:,1)<=bxl,xy(:,1)>=bxr,xy(:,2)>=byb,xy(:,2)<=byt];
    f.tracking_info.periphery(i,:) = any(criteria,2)';
end

