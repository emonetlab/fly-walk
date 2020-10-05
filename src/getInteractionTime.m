function t = getInteractionTime(f,this_fly,this_frame)
% calculates how long the given fly has been interacting since the given
% farem number

if nargin==2
    this_frame = f.current_frame;
end

if isnan(f.tracking_info.collision(this_fly,this_frame))&&isnan(f.tracking_info.overpassing(this_fly,this_frame))
    t = 0;
else
    if isnan(f.tracking_info.collision(this_fly,this_frame))
        last_t = find(isnan(f.tracking_info.overpassing(this_fly,1:this_frame)),1,'last');
    elseif isnan(f.tracking_info.overpassing(this_fly,this_frame))
        last_t = find(isnan(f.tracking_info.collision(this_fly,1:this_frame)),1,'last');
    else
        last_ct = find(isnan(f.tracking_info.overpassing(this_fly,1:this_frame)),1,'last');
        last_ot = find(isnan(f.tracking_info.collision(this_fly,1:this_frame)),1,'last');
        last_t = min(last_ct,last_ot);
    end
    
    t = (this_frame-last_t)/f.ExpParam.fps;
end