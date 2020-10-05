function f = getCIZoneStatus(f)
% checks if flies are in the collision ignore zone (about 2 body length:
% ~7 mm) and save it in
% tracking_info.periphery

% get zone edges
if f.apply_mask
    bxl = f.ExpParam.source.x+f.edge_coll_ignore_dist;
    bxr = size(f.current_raw_frame,2)-f.ExpParam.crop_box.rcrp-f.edge_coll_ignore_dist;
    byt = f.ExpParam.crop_box.tcrp+f.edge_coll_ignore_dist;
    byb = size(f.current_raw_frame,1)-f.ExpParam.crop_box.bcrp-f.edge_coll_ignore_dist;
else
    bxl = f.ExpParam.source.x+f.edge_coll_ignore_dist;
    bxr = size(f.current_raw_frame,2)-f.edge_coll_ignore_dist;
    byt = 1+f.edge_coll_ignore_dist;
    byb = size(f.current_raw_frame,1)-f.edge_coll_ignore_dist;
end

f.tracking_info.coligzone = zeros(size(f.tracking_info.signal));
tot_num_of_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');


for i = 1:tot_num_of_flies
    xy = [f.tracking_info.x(i,:)',f.tracking_info.y(i,:)']; 
    criteria = [xy(:,1)<=bxl,xy(:,1)>=bxr,xy(:,2)>=byb,xy(:,2)<=byt];
    f.tracking_info.coligzone(i,:) = any(criteria,2)';
end