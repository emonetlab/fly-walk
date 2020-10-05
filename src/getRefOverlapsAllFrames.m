function f = getRefOverlapsAllFrames(f)
%getRevOverlapsAllFrames
%   f = getRevOverlapsAllFrames(f)
%   calculates the reflection overlaps on all frames
%

% set all reflection overlaps to nan and/or allocate space
f.tracking_info.refOverLap1 =  nan(size(f.tracking_info.x,1),size(f.tracking_info.x,2));
f.tracking_info.refOverLap2 =  nan(size(f.tracking_info.x,1),size(f.tracking_info.x,2));

for i = 1:f.nframes
 f = getRefOverlapsAllFLies(f,i);
end