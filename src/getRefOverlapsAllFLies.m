function f = getRefOverlapsAllFLies(f,frameNum)
%getRefOverlapsAllFLies
%   f = getRefOverlapsAllFLies(f,frameNum)
%   calculates the reflection overlaps of all flies in the given
%   frameNumber. Reflection overlaps of both 1. and 2. reflections are
%   calcualted for each fly.
%

if nargin==1
    frameNum = f.current_frame;
end

if f.current_frame~=frameNum
    f.previous_frame = f.current_frame;
    f.current_frame = frameNum; 
    f.operateOnFrame;
end
if isempty(f.current_objects)  
    f.operateOnFrame;
end
% get currently assigned flies
theseFlies = find(f.tracking_info.fly_status(:,frameNum)==1);
if isempty(theseFlies)
    disp('there are no flies on this frame. Skipping...')
    return
end

% get all fly pixel list
[~,AllFlyPxlList] = getFlyNRefMaskSigMeas(f,[]); % [] secifies that no reflection is involved in this pixel list
% get all reflection pixels list
RefPxlListR = getReflPxls(f);
% go over all flies and get reflection overlaps of both 1 and 2
for flyInd = 1:length(theseFlies)
    flyNum = theseFlies(flyInd);
    f = getRefOlap(f,flyNum,RefPxlListR,AllFlyPxlList);
end