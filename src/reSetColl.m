function f = reSetColl(f,this_fly,colliders,frame_num)
% restes the collision list

if nargin == 3
    frame_num = f.current_frame;
end

if isempty(colliders)
    return
end

if length(colliders)==1
   f.tracking_info.collision(this_fly,frame_num) = NaN;
   f.tracking_info.collision(colliders,frame_num) = NaN;
else
   f.tracking_info.collision(this_fly,frame_num) = NaN;
   for i = 1:length(colliders)
       f.tracking_info.collision(colliders(i),frame_num) = NaN;
   end
end