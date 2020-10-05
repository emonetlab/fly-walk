function f = setColl(f,this_fly,colliders,frame_num)
% returns the list of flies colliding with this_fly in frame frame_num

if nargin == 3
    frame_num = f.current_frame;
end

if isempty(colliders)
    return
end

if length(colliders)==1
   f.tracking_info.collision(this_fly,frame_num) = colliders;
   f.tracking_info.collision(colliders,frame_num) = this_fly;
else
   f.tracking_info.collision(this_fly,frame_num) = -f.collsind;
   f.CollS(f.collsind) = {colliders};
   f.collsind = f.collsind + 1;
   for i = 1:length(colliders)
       f.tracking_info.collision(colliders(i),frame_num) = this_fly;
   end
end