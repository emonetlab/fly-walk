function f = reSetOver(f,this_fly,overlaps,frame_num)
% resets the ovrpassing list

if nargin == 3
    frame_num = f.current_frame;
end

if isempty(overlaps)
    return
end

if length(overlaps)==1
   f.tracking_info.overpassing(this_fly,frame_num) = NaN;
   f.tracking_info.overpassing(overlaps,frame_num) = NaN;
else
   f.tracking_info.overpassing(this_fly,frame_num) = NaN;
   for i = 1:length(overlaps)
       f.tracking_info.overpassing(overlaps(i),frame_num) = NaN;
   end
end