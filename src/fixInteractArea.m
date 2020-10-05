function f = fixInteractArea(f)
% fixs the area of all interacting flies. Otehrwise the interaction area
% criteria does not work. Flies become smaller and smaller.

these_flies = find(~isnan(f.tracking_info.collision(:,f.current_frame)));

for i = 1:length(these_flies)
    this_fly = these_flies(i);
    if f.current_frame-1-f.interact_area_fix_legth>0
        this_area_vec = f.tracking_info.area(this_fly,f.current_frame-1-f.interact_area_fix_legth:f.current_frame-1);
    else
        this_area_vec = f.tracking_info.area(this_fly,1:f.current_frame-1);
    end
%     f.tracking_info.area(this_fly,f.current_frame) = f.tracking_info.area(this_fly,f.current_frame-1);
    f.tracking_info.area(this_fly,f.current_frame) = mean(this_area_vec);
end
