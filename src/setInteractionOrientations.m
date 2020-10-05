function orientation = setInteractionOrientations(orientation,fs,fe,activeFrames,angle_flip_threshold)
% sets the orientation during the interactions. takes the following segment
% as the basis. If there is not a following segment uses the previous one.

% check if interaction starts at the first frame
if fs(1)>activeFrames(1)
    for segin = fs(1)-1:-1:activeFrames(1)
        % allign orientations with the following one
        orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
    end
else
    for segnum = 1:length(fs)-1
        for segin = fs(segnum+1)-1:-1:fe(segnum)+1
            % allign orientations with the following one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
        end
    end
end
% deial with the last one if the track ends in an interaction
if fe(end)<activeFrames(end)
    for segin = fe(end)+1:activeFrames(end)
        % allign orientations with the previous one
        orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
    end
end