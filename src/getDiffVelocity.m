function [vx,vy] = getDiffVelocity(f,resolve_this,frame_num)
%getDiffVelocity
% [vx,vy] = getDiffVelocity(f,resolve_this,frame_num) returns the speed (x,y)
% the fly (resolve_this) at frame_num (default current_frame) by
% differentiating previous location from current location. If frame_num is
% 1, returns nan
%

switch nargin
    case 2
        frame_num = f.current_frame;
end

if frame_num==1
    vx = NaN;
    vy = NaN;
    return
end

vx = diff(f.tracking_info.x(resolve_this,frame_num-1:frame_num));
vy = diff(f.tracking_info.y(resolve_this,frame_num-1:frame_num));