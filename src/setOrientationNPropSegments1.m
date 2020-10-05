function orientation = setOrientationNPropSegments1(orientation,heading,fs,fe,frameWmaxSpeed,usefulFrames,angle_flip_threshold)
% this code first allign all useful frames and than fills the gaps starting
% with the segment containingthe hishest speed of the fly

% allign all usefull frames first
orientation  = allignAllUsefulFrames(orientation,heading,usefulFrames,angle_flip_threshold);

% find in which segment the frame with maximum speed is
segstart = find(fs<=frameWmaxSpeed,1,'last');

% make sure that it is actually in the segment
if fe(segstart)<frameWmaxSpeed
    disp('Frame with the max speed seems to be larger than the segment end')
    keyboard
end

% get the up and down segment indexes
segmentNums = 1:length(fs);
downInd = segmentNums(1:find(segmentNums==segstart)-1);
upInd = segmentNums(find(segmentNums==segstart)+1:end);

% start with the segment with the highest speed
% find the first un-usefull frame in this segment
segframes = fs(segstart):fe(segstart);
segnuis = segframes; 
segnuis(logical(sum(segframes==usefulFrames',1))) = [];

if ~isempty(segnuis)
    if segnuis(1)==fs(segstart)
        % find the first useful frame
        seguis = segframes(find(sum(segframes==usefulFrames',1),1));
        for segin = seguis-1:-1:segnuis(1)
            % allign the orientations
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
        end
        % find the next not useful frame upward and and do the rest
        segnuis(segnuis<seguis) = []; % delete the processed ones
        % do the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
    else
        % do all the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
    end
end

% now move up and down in the sequences
for k = 1:length(upInd)
    indnum = upInd(k);
    
    % find the first usefull frame in this segment
segframes = fs(indnum):fe(indnum);
segnuis = segframes; 
segnuis(logical(sum(segframes==usefulFrames',1))) = [];

if ~isempty(segnuis)
    if segnuis(1)==fs(indnum)
        % find the first useful frame
        seguis = segframes(find(sum(segframes==usefulFrames',1),1));
        if isempty(seguis)
            % there is not any useful frames in thie segment. allign with
            % previous end
            orientation(fs(indnum)) = AllignOrient2Ref(orientation(fs(indnum)),orientation(fe(indnum-1)),angle_flip_threshold);
            segnuis(1) = []; %already alligned that
            for segin = segnuis
                % allign orientations with the previous one
                orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
            end
        else
            
        for segin = seguis-1:-1:segnuis(1)
            % allign the orientations
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
        end
        % find the next not useful frame upward and and do the rest
        segnuis(segnuis<seguis) = []; % delete the processed ones
        % do the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
        end
    else
        % do all the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
    end
end
    
end

% down the sequence
for k = length(downInd):-1:1
    indnum = downInd(k);
        % find the first usefull frame in this segment
segframes = fs(indnum):fe(indnum);
% find not useful frames
segnuis = segframes; 
segnuis(logical(sum(segframes==usefulFrames',1))) = [];

if ~isempty(segnuis)
    if segnuis(1)==fs(indnum)
        % find the first next useful frame
        seguis = segframes(find(sum(segframes==usefulFrames',1),1));
        if isempty(seguis)
            % there is not any useful frames in thie segment. allign with
            % next start
            orientation(fe(indnum)) = AllignOrient2Ref(orientation(fe(indnum)),orientation(fs(indnum+1)),angle_flip_threshold);
            segnuis(end) = []; %already alligned that
            for segini = length(segnuis):-1:1
                segin = segnuis(segini);
                % allign orientations with the next one
                orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
            end
        else
            
        for segin = seguis-1:-1:segnuis(1)
            % allign the orientations
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin+1),angle_flip_threshold);
        end
        % find the next not useful frame upward and and do the rest
        segnuis(segnuis<seguis) = []; % delete the processed ones
        % do the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
        end
    else
        % do all the rest
        for segin = segnuis
            % allign orientations with the previous one
            orientation(segin) = AllignOrient2Ref(orientation(segin),orientation(segin-1),angle_flip_threshold);
        end
    end
end
end




