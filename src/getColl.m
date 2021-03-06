function colliders = getColl(f,this_fly,frame_num)
% returns the list of flies colliding with this_fly in frame frame_num

if nargin == 2
    frame_num = f.current_frame-1;
end


if isnan(f.tracking_info.collision(this_fly,frame_num))
    colliders = [];
elseif sign(f.tracking_info.collision(this_fly,frame_num))==1
    colliders = f.tracking_info.collision(this_fly,frame_num);
else
    colliders  = f.CollS{int16(-f.tracking_info.collision(this_fly,frame_num))};
end