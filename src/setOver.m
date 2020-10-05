function f = setOver(f,this_fly,overlaps,frame_num)
% returns the list of flies colliding with this_fly in frame frame_num

if nargin == 3
    frame_num = f.current_frame;
end

if isempty(overlaps)
    return
end

if length(overlaps)==1
   f.tracking_info.overpassing(this_fly,frame_num) = overlaps;
   f.tracking_info.overpassing(overlaps,frame_num) = this_fly;
else
   f.tracking_info.overpassing(this_fly,frame_num) = -f.oversind;
   f.OverS(f.oversind) = {overlaps};
   f.oversind = f.oversind + 1;
   for i = 1:length(overlaps)
       f.tracking_info.overpassing(overlaps(i),frame_num) = this_fly;
   end
end