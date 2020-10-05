function flynsurf = getFlySurface(f,this_fly,frame_num)
% return the fly number with the sign of the surface. + top surface, -
% bottom surface

if nargin==2
    frame_num = f.current_frame-1;
end

flynsurf = zeros(size(this_fly));

for i = 1:length(this_fly)
    the_fly = this_fly(i);
    if f.reflection_status(the_fly,frame_num)
        flynsurf(i) = the_fly;
    else
        flynsurf(i) = -the_fly;
    end
end
    