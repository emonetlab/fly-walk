function status = isIntheCollignoreZone(f,xy)
%iisIntheCollignoreZone determines if a given point xy is in the collision
%ignore zone. The source side is not considered

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


% define the criteria
criteria = [xy(:,1)<=bxl,xy(:,1)>=bxr,xy(:,2)>=byb,xy(:,2)<=byt];

status = any(criteria,2);