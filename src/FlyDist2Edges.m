function pdistm = FlyDist2Edges(f,this_fly)

if f.apply_mask
    bxl = f.ExpParam.source.x;
    bxr = size(f.current_raw_frame,2)-f.ExpParam.crop_box.rcrp;
    byt = f.ExpParam.crop_box.tcrp;
    byb = size(f.current_raw_frame,1)-f.ExpParam.crop_box.bcrp;
else
    bxl = f.ExpParam.source.x;
    bxr = size(f.current_raw_frame,2);
    byt = 1;
    byb = size(f.current_raw_frame,1);
end

% calculate the perpendicular distances to walls
pdistm = abs([f.tracking_info.x(this_fly,f.current_frame)-bxl,...
    bxr-f.tracking_info.x(this_fly,f.current_frame),...
    f.tracking_info.y(this_fly,f.current_frame)-byt,...
    byb-f.tracking_info.y(this_fly,f.current_frame)]);

    
if (f.ft_debug) && (f.tracking_info.fly_status(this_fly,f.current_frame-1) == 1) &&(any(pdistm<=f.dist_fly_edge_leave))
    % determine where it left the boundary

    labdist = {'left','right','top','bottom'};
    disp(['Fly:',num2str(this_fly),' too close to the ',labdist{pdistm==min(pdistm)},' wall. x=',...
        num2str(round(f.tracking_info.x(this_fly,f.current_frame))),...
        ' y=',num2str(round(f.tracking_info.y(this_fly,f.current_frame)))])
    disp(['distance to the closest -',labdist{pdistm==min(pdistm)},'- border is ',...
        num2str(round(min(pdistm))),' pxl(s)'])


end