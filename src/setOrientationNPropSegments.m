function orientation = setOrientationNPropSegments(orientation,heading,fs,fe,speedFly,frameWmaxSpeed,usefullFrames,angle_flip_threshold,NConsecSpeedAllign)

switch nargin
    case 8
        NConsecSpeedAllign = 3; % allign and verify the orientation for this many consecutive frames
    case 7
        NConsecSpeedAllign = 3; % allign and verify the orientation for this many consecutive frames
        angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
end


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
% get usefull frames in this segment
thisUF = usefullFrames;
thisUF(thisUF>fe(segstart)) = [];
thisUF(thisUF<fs(segstart)) = [];

% give some buffer to maximum speed frame (i.e. NconsecSpeedAllign frames
% before it)
thisind = thisUF==frameWmaxSpeed;
thisUF(1:thisind-NConsecSpeedAllign) = [];

% get the start frame for usefull frames that meet speed criteria
ConsStart = findConsecutiveStart(thisUF,NConsecSpeedAllign,5); % request 5 of these

if isempty(ConsStart) % use only the start frame
    % allign the first frame of these Consecutive frames to heading
    orientation(frameWmaxSpeed) = AllignOrient2Ref(orientation(frameWmaxSpeed),heading(frameWmaxSpeed));
    
    % set and propogate this orientation to rest of the frames
    orientation = SetNPropOrientation(orientation,frameWmaxSpeed,angle_flip_threshold,[fs(segstart),fe(segstart)]);
    
else % there are consecutive frames
    % use the first one for now
    ConsStart = ConsStart(1);
    % measure all orientations and check and verify the allignment
    if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
        % allign the fist point and propagate
        orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
        
        % set and propogate this orientation to rest of the frames
        orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(segstart),fe(segstart)]);
        
    else % the sequence is not reliable
        thisUFup = thisUF;
        found = 0;
        while ((length(thisUFup)-3)>=3)&&(~found)
            disp('Heading sequence is not reliable. Crop & re-check...')
            thisUFup(thisUFup<(ConsStart+NConsecSpeedAllign-1)) = []; % crop the not-relibale part
            % get the start frame for usefull frames that meet speed criteria
            ConsStart = findConsecutiveStart(thisUFup,NConsecSpeedAllign,1); % request 1 of these
            if isempty(ConsStart) % use only the start frame
                found = 1;
                % allign the first frame of these Consecutive frames to heading
                orientation(thisUFup(1)) = AllignOrient2Ref(orientation(thisUFup(1)),heading(thisUFup(1)));
                
                % set and propogate this orientation to rest of the frames
                orientation = SetNPropOrientation(orientation,thisUFup(1),angle_flip_threshold,[fs(segstart),fe(segstart)]);
                
            else % there are consecutive frames
                % measure all orientations and check and verify the allignment
                if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
                    found = 1;
                    % allign the first point and propagate
                    orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
                    
                    % set and propogate this orientation to rest of the frames
                    orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(segstart),fe(segstart)]);
                else
                end
            end
        end
    end
    
end

% now move up and down in the sequences
for k = 1:length(upInd)
    indnum = upInd(k);
    % get usefull frames in this segment
    thisUF = usefullFrames;
    thisUF(thisUF>fe(indnum)) = [];
    thisUF(thisUF<fs(indnum)) = [];
    
    if isempty(thisUF) % fly seems to be at rest in this sequences
        % allign it with the orientation with the previous segment
        orientation(fs(indnum)) = AllignOrient2Ref(orientation(fs(indnum)),orientation(fe(indnum-1)));
        % set and propogate this orientation to rest of the frames
        if isnan(orientation(fs(indnum)))
            continue
        else
%             if indnum==2
%                 keyboard
%             end
            orientation = SetNPropOrientation(orientation,fs(indnum),angle_flip_threshold,[fs(indnum),fe(indnum)]);
        end
        
    else % find the allignment sequence
        % find the highest speed in this sequence
        frameWmaxSpeed = find(speedFly==max(speedFly(thisUF)),1); % ensure getting only one point
        % give some buffer to maximum speed frame (i.e. NconsecSpeedAllign frames
        % before it)
        thisind = thisUF==frameWmaxSpeed;
        thisUF(1:thisind-NConsecSpeedAllign) = [];
        % get the start frame for usefull frames that meet speed criteria
        ConsStart = findConsecutiveStart(thisUF,NConsecSpeedAllign,5); % request 5 of these
        
        if isempty(ConsStart) % use only the start frame
            % allign the first frame of these Consecutive frames to heading
            orientation(thisUF(1)) = AllignOrient2Ref(orientation(thisUF(1)),heading(thisUF(1)));
            
            % set and propogate this orientation to rest of the frames
            orientation = SetNPropOrientation(orientation,thisUF(1),angle_flip_threshold,[fs(indnum),fe(indnum)]);
            disp('First point is taken as relibale point')
            
        else % there are consecutive frames
            % use the first one for now
            ConsStart = ConsStart(1);
            % measure all orientations and check and verify the allignment
            if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
                % allign the fist point and propagate
                orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
                
                % set and propogate this orientation to rest of the frames
                orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(indnum),fe(indnum)]);
                
            else % the sequence is not reliable
                % move up in the sequence until one is found
                thisUFup = thisUF;
                found = 0;
                while ((length(thisUFup)-3)>=3)&&(~found)
                    disp('Heading sequence is not reliable. Crop & re-check...')
                    thisUFup(thisUFup<(ConsStart+NConsecSpeedAllign-1)) = []; % crop the not-relibale part
                    % get the start frame for usefull frames that meet speed criteria
                    ConsStart = findConsecutiveStart(thisUFup,NConsecSpeedAllign,1); % request 1 of these
                    if isempty(ConsStart) % use only the start frame
                        found = 1;
                        % allign the first frame of these Consecutive frames to heading
                        orientation(thisUFup(1)) = AllignOrient2Ref(orientation(thisUFup(1)),heading(thisUFup(1)));
                        
                        % set and propogate this orientation to rest of the frames
                        orientation = SetNPropOrientation(orientation,thisUFup(1),angle_flip_threshold,[fs(indnum),fe(indnum)]);
                        
                    else % there are consecutive frames
                        % measure all orientations and check and verify the allignment
                        if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
                            found = 1;
                            % allign the fist point and propagate
                            orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
                            
                            % set and propogate this orientation to rest of the frames
                            orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(indnum),fe(indnum)]);
                        else
                        end
                    end
                end
                
                if ~found
                    % if still not found set the last point before the segment
                    % ends
                    % allign the first frame of these Consecutive frames to heading
                    orientation(thisUF(end)) = AllignOrient2Ref(orientation(thisUF(end)),heading(thisUF(end)));
                    
                    % set and propogate this orientation to rest of the frames
                    orientation = SetNPropOrientation(orientation,thisUF(end),angle_flip_threshold,[fs(indnum),fe(indnum)]);
                    disp('Last point is taken as relibale point')
                end
                
                
            end
            
        end
    end
end

% down the sequence
for k = length(downInd):-1:1
    indnum = downInd(k);
    % get usefull frames in this segment
    thisUF = usefullFrames;
    thisUF(thisUF>fe(indnum)) = [];
    thisUF(thisUF<fs(indnum)) = [];
    
    if isempty(thisUF) % fly seems to be at rest in this sequences
        % allign it with the orientation with the next segment
        orientation(fe(indnum)) = AllignOrient2Ref(orientation(fe(indnum)),orientation(fs(indnum+1)));
        if isnan(orientation(fe(indnum)))
            continue
        else
            % set and propogate this orientation to rest of the frames
            orientation = SetNPropOrientation(orientation,fe(indnum),angle_flip_threshold,[fs(indnum),fe(indnum)]);
        end
        
    else % find the allignment sequence
        % find the highest speed in this sequence
        frameWmaxSpeed = find(speedFly==max(speedFly(thisUF)),1); % ensure getting only one point
        % give some buffer to maximum speed frame (i.e. NconsecSpeedAllign frames
        % before it)
        thisind = thisUF==frameWmaxSpeed;
        thisUF(1:thisind-NConsecSpeedAllign) = [];
        % get the start frame for usefull frames that meet speed criteria
        ConsStart = findConsecutiveStart(thisUF,NConsecSpeedAllign,5); % request 5 of these
        
        
        if isempty(ConsStart) % use only the start frame
            % allign the first frame of these Consecutive frames to heading
            orientation(thisUF(1)) = AllignOrient2Ref(orientation(thisUF(1)),heading(thisUF(1)));
            % set and propogate this orientation to rest of the frames
            orientation = SetNPropOrientation(orientation,thisUF(1),angle_flip_threshold,[fs(indnum),fe(indnum)]);
            
        else % there are consecutive frames
            % use the first one for now
            ConsStart = ConsStart(1);
            % measure all orientations and check and verify the allignment
            if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
                % allign the fist point and propagate
                orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
                
                % set and propogate this orientation to rest of the frames
                orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(indnum),fe(indnum)]);
                
            else % the sequence is not reliable
                % move up in the sequence until one is found
                thisUFup = thisUF;
                found = 0;
                while ((length(thisUFup)-3)>=3)&&(~found)
                    disp('Heading sequence is not reliable. Crop & re-check...')
                    thisUFup(thisUFup<(ConsStart+NConsecSpeedAllign-1)) = []; % crop the not-relibale part
                    % get the start frame for usefull frames that meet speed criteria
                    ConsStart = findConsecutiveStart(thisUFup,NConsecSpeedAllign,1); % request 1 of these
                    if isempty(ConsStart) % use only the start frame
                        found = 1;
                        % allign the first frame of these Consecutive frames to heading
                        orientation(thisUFup(1)) = AllignOrient2Ref(orientation(thisUFup(1)),heading(thisUFup(1)));
                        
                        % set and propogate this orientation to rest of the frames
                        orientation = SetNPropOrientation(orientation,thisUFup(1),angle_flip_threshold,[fs(indnum),fe(indnum)]);
                        
                    else % there are consecutive frames
                        % measure all orientations and check and verify the allignment
                        if isHeadingSeqReliable(heading(ConsStart:(ConsStart+NConsecSpeedAllign-1)),angle_flip_threshold)
                            found = 1;
                            % allign the fist point and propagate
                            orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),heading(ConsStart));
                            
                            % set and propogate this orientation to rest of the frames
                            orientation = SetNPropOrientation(orientation,ConsStart,angle_flip_threshold,[fs(indnum),fe(indnum)]);
                        else
                        end
                    end
                end
                
            end
            
        end
    end
end

end



