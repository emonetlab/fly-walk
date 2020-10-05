function allInteractions = getAllInteractions(f,framenum)
% gets the list of all interactions in the given frame
% allInteractions : [flyInt1 flyInt2 ; ...]

if nargin==1
    framenum = f.current_frame;
end

allInteractions = [];

for i = 1:size(f.tracking_info.fly_status,1)
    thisInt = getInteractions(f,i,framenum);
    if isempty(thisInt)
        continue
    else
        for j =1:length(thisInt)
            allInteractions = [allInteractions;[i thisInt(j)]];
        end
    end
end