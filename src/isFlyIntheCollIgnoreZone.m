function status = isFlyIntheCollIgnoreZone(f,this_fly)
%isInthePeriferi determines if a given fly is in the periferi, which
%is whether the point is close to the edges more than
%f.dist_fly_edge_leave. Calculaed using the tracking data

status = false(size(this_fly));

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


% go over flies
for i = 1:length(this_fly)
    xy = [f.tracking_info.x(this_fly(i),f.current_frame),f.tracking_info.y(this_fly(i),f.current_frame)]; 
    % define the criteria
    criteria = [xy(1)<=bxl,xy(1)>=bxr,xy(2)>=byb,xy(2)<=byt];

    if any(criteria)
        status(i) = true;
    end
end

