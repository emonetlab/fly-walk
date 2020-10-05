function status = isInthePeriferi(f,xy)
%isInthePeriferi determines if a given point xy is in the periferi, which
%is whether the point is close to the edges more than f.dist_fly_edge_leave

% get zone edges
if f.apply_mask
    bxl = f.ExpParam.source.x + f.dist_fly_edge_leave;
    bxr = size(f.current_raw_frame,2)-f.ExpParam.crop_box.rcrp-f.dist_fly_edge_leave;
    byt = f.ExpParam.crop_box.tcrp+f.dist_fly_edge_leave;
    byb = size(f.current_raw_frame,1)-f.ExpParam.crop_box.bcrp-f.dist_fly_edge_leave;
else
    bxl = f.ExpParam.source.x+f.dist_fly_edge_leave;
    bxr = size(f.current_raw_frame,2)-f.dist_fly_edge_leave;
    byt = 1+f.dist_fly_edge_leave;
    byb = size(f.current_raw_frame,1)-f.dist_fly_edge_leave;
end

% define the criteria
criteria = [xy(1)<=bxl,xy(1)>=bxr,xy(2)>=byb,xy(2)<=byt];

if any(criteria)
    status = true;
else
    status = false;
end
