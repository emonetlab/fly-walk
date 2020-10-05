function status = isFlyInthePeriferi(f,this_fly,framenum)
%isInthePeriferi determines if a given fly is in the periferi, which
%is whether the point is close to the edges more than
%f.dist_fly_edge_leave. Calculaed using the tracking data
if nargin==2
    framenum = f.current_frame;
end

status = false(size(this_fly));

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


% go over flies
for i = 1:length(this_fly)
    xy = [f.tracking_info.x(this_fly(i),framenum),f.tracking_info.y(this_fly(i),framenum)]; 
    % define the criteria
    criteria = [xy(1)<=bxl,xy(1)>=bxr,xy(2)>=byb,xy(2)<=byt];

    if any(criteria)
        status(i) = true;
    end
end
