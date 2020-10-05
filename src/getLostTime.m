function t = getLostTime(f,this_fly,this_frame)
% calculates how long the given fly has been lost prior the given
% frame number

if nargin==2
    this_frame = f.current_frame;
end

if (f.tracking_info.fly_status(this_fly,this_frame)<=0)
    t = 0;
else
    last_t = find(f.tracking_info.fly_status(this_fly,1:this_frame)==1,1,'last')+1;
    t = (this_frame-last_t)/f.ExpParam.fps;
end
