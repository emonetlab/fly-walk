function f = PostProcessOrientations(f)
% some parameters
NConsec = 10; % number of ceonsecutive frames for gradient orientation estimation
NConsecSpeedAllign = 3; % number of consecutive frames for orientation heading allignment verification
speedSmthLen = round(f.tracking_info.speedSmthlen);  % smooth length for speed that is used to be thresolded
% angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
angle_flip_threshold = f.tracking_info.angle_flip_threshold;
maskdilate = 5; % dilation to avoid interactions and jumps

% get total number of flies
NFlies = find(f.tracking_info.fly_status(:,end)~=0,1,'last');

if f.ft_debug
    disp(['Post Porcessing Orientations. There are ',num2str(NFlies), ' flies'])
end

% loop over the flies and handle the orientations
for thisFly = 1:NFlies
    
    if f.ft_debug
        disp(['Fly: ',num2str(thisFly)])
    end
    
    % get speed of the fly
    speedFly = smooth(getFlyDiffVel(f,thisFly),speedSmthLen);
    speedFly(isnan(getFlyDiffVel(f,thisFly))) = NaN;
    % get the orientation
    orientation = f.tracking_info.orientation(thisFly,:);
    % get the heading
    heading = f.tracking_info.heading(thisFly,:);
    
    % points where mean speed (smoothed by 1 sec) is above the speed threshold
    thesePoints = speedFly'>f.immobile_speed*f.heading_allignment_factor;
    
    % get the speed allignment mask, true is not valid point
    [mask,maskInt] = getSpeedAllignMask(f,thisFly,maskdilate);
    
    % find usefull frame numbers
    usefullFrames = find(thesePoints.*~mask);
    
    % get active frames
    activeFrames = find(f.tracking_info.fly_status(thisFly,:)==1,1):find(f.tracking_info.fly_status(thisFly,:)==1,1,'last'); % first frame:last frame
    not_active_frames = 1:length(orientation);
    not_active_frames(activeFrames) = [];
    
    
    % if usefull frames is empty, therefore this track is either almost always
    % at the border, or motionless.
    if isempty(usefullFrames)
        if f.ft_debug
            disp('There not any usefull frames. Fly must be almost always at the border, or at rest')
        end
        %% find regions where fly is fully in the arena and free of interaction
        % and away from the borders
        maskpoints = find(~mask); % not interacting etc
        maskpoints(logical(sum(maskpoints==not_active_frames',1)))=[]; % ignore the points where the fly is lost
        ConsStart = findConsecutiveStart(maskpoints,NConsec);
        % if there is not any consecutive series, use only the first one
        if isempty(ConsStart)
            if f.ft_debug
                disp(['Could not find ',num2str(NConsec),' consecutive frames for pixel intensity gradient estimation'])
                disp('will use the gradient of the frame with a fly size close to median')
            end
            medframes = find(f.tracking_info.area(thisFly,:)>=nanmedian(f.tracking_info.area(thisFly,activeFrames)),10); % get 10 frames
            if isempty(medframes)
                medframes = activeFrames;
            end
            
            % get the gradient of this fly at the first point
            % put all of these frames in a loop until it reaches to frame
            % with relibale fly intensity gradient
            for medframe = medframes
                f.previous_frame = f.current_frame;
                f.current_frame = medframe;
                f.operateOnFrame;
                theta = getFlyGradOrientation(f,thisFly);
                if ~isempty(theta)
                    orientation(medframe) = theta;
                    setPoint = medframe;
                    disp(['Fly gradient intensity on frame# ',num2str(medframe),' will be used'])
                    break
                end
            end
            
            % if all of these frames are not useful, use the first active
            % frame for the reference
            if isempty(theta)
                FramesWithUsefullOrientations = activeFrames(~isnan(orientation(activeFrames)));
                setPoint = randsample(FramesWithUsefullOrientations,1);
%                 setPoint = activeFrames(randi(length(activeFrames),1));
                disp('None of the searched frames produced a relibale fly gradient intensity')
                disp(['Regionprops generated orientation on the randomly selected frame# ',num2str(setPoint),' will be used'])
            end
                
            
            % set this orientation for the rest
            orientation = SetNPropOrientation(orientation,setPoint,angle_flip_threshold);
        else % get mean orientation of these NConsec frames
            if f.ft_debug
                disp(['Found ',num2str(NConsec),' consecutive frames for pixel intensity gradient estimation'])
                disp('will average them and set the orientation')
            end
            
            oritemp = zeros(NConsec,1);
            for frmnum = ConsStart:ConsStart+NConsec-1
                % get the gradient of this fly at the first point
                f.previous_frame = f.current_frame;
                f.current_frame = frmnum;
                f.operateOnFrame;
                theta = getFlyGradOrientation(f,thisFly);
                if isempty(theta)
                    oritemp(frmnum) = nan;
                else
                    oritemp(frmnum) = theta;
                end
            end
            
            % there must be at leat one usefull frame
            if sum(isnan(oritemp))==length(oritemp)
                disp('These frames are not relibale. solve this problem')
                keyboard;   
            else
                oritemp(isnan(oritemp)) = []; % remove nans
            end
            
            meanTheta = meanOrientation(oritemp);
            
            % allign the first frame of these Consecutive frames to mean Theta
            orientation(ConsStart) = AllignOrient2Ref(orientation(ConsStart),meanTheta);
            
            % set and propogate this orientation to rest of the frames
            orientation = SetNPropOrientation(orientation,ConsStart);
        end
        
    else % there are usefull frames for orientation heading allignment
        if f.ft_debug
            disp('There are some usefull frames. Will try to allign the heading with the orientations')
        end
        
        
        % find the usefull frame with highest speed
        frameWmaxSpeed = find(speedFly==max(speedFly(usefullFrames)),1); % ensure getting only one point
        
        % points where some interaction happens or fly is lost
        [pil,nil] = getOnOffPoints(diff(maskInt));
        % merge them
        [pil,nil] = MergeOnOffPoints(pil,nil);
        
        % get segment starts and ends excluding the interactions
        [fs,fe] = getSegmentEdges(pil,nil,activeFrames);
        
        % start with index that has the highest speed and propagate left and right
        orientation = setOrientationNPropSegments(orientation,heading,fs,fe,speedFly,frameWmaxSpeed,usefullFrames,angle_flip_threshold,NConsecSpeedAllign);
        
        % allign the interaction frames to following segment
        orientation = setInteractionOrientations(orientation,fs,fe,activeFrames,angle_flip_threshold);
        
    end
    
    % save the orientation
    f.tracking_info.orientation(thisFly,:) = orientation;
    
end
if f.ft_debug
    disp(['Orientation of all ',num2str(NFlies), ' flies are post processed...'])
end

%% find the max speed which is free of interactions and valid for speed
% allignment

%% if there is not any valid speed point



%% if there is gather gradient directions for several frames and assign
% the most frequent one

%% if there is not: gather several frames where the fly size is largest
% and assign the direction of the most frequent one

%% if valid speed points found

%% 1- find 3 consecutive points, allign and verify

%% move up and down by enforcing the valid orientation until the borders of
% the segment.

%% move up and down in the segments and repeat the routine