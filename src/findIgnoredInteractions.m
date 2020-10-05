function f = findIgnoredInteractions(f,framenum)
% figures out the ignored interactions, possibly due to the collision
% ignore zoen and registers them to the ignored interaction matrix under
% tracing_info

if nargin==1
    framenum = f.current_frame;
end

suspInt = findSuspectedInteractions(f,framenum);

if isempty(suspInt)
    return
end

for i = 1:size(suspInt,1)
    f.tracking_info.IgnoredInteractions(suspInt(i,1),framenum) = suspInt(i,2);
    f.tracking_info.IgnoredInteractions(suspInt(i,2),framenum) = suspInt(i,1);
end