function orientation  = allignAllUsefulFrames(orientation,heading,usefulFrames,angle_flip_threshold)
% allign the orientation of the flies to its heading for the given frame
% sequence
for i = 1:length(usefulFrames)
    thisFrame = usefulFrames(i);
    orientation(thisFrame) = AllignOrient2Ref(orientation(thisFrame),heading(thisFrame),angle_flip_threshold);
end