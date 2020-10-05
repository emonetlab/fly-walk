function overlaps = getOver(f,this_fly,frame_num)
% returns the list of flies colliding with this_fly in frame frame_num

if nargin == 2
    frame_num = f.current_frame-1;
end


if isnan(f.tracking_info.overpassing(this_fly,frame_num))
    overlaps = [];
elseif sign(f.tracking_info.overpassing(this_fly,frame_num))==1
    overlaps = f.tracking_info.overpassing(this_fly,frame_num);
else
    overlaps  = f.OverS{int16(-f.tracking_info.overpassing(this_fly,frame_num))};
end