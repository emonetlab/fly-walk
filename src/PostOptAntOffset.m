%PostOptAntOffset
% this function is meant to be run after post processing the orientations.
% However it can be run with or with out the orientation fixs. This code
% will find the good frames that excludes the fly interactions, jumps, and
% peripheries and optimizes the antenna location at N consecutive frames
% defined in f.length_aos_mat. Optimization is done by moving the virtual
% antenna towards fly center after dilating the fly by antenna_opt_dil_n
% until the overlap between the antenna and the virtual antenna is zero
%

function f = PostOptAntOffset(f)

% some parameters to determine good frames
speedSmthLen = round(f.tracking_info.speedSmthlen);  % smooth length for speed that is used to be thresolded
maskdilate = 5; % dilation to avoid interactions and jumps



% get total number of flies
NFlies = find(f.tracking_info.fly_status(:,end)~=0,1,'last');

% initiate a list for flies which are always in interaction or at the
% border etc. These flies will be assigned the mean value of the usefull
% flies
bad_flies = zeros(1,NFlies);

if f.ft_debug
    disp(['Post Porcessing Antenna Location Optimization. There are ',num2str(NFlies), ' flies'])
end

% loop over the flies and handle the antanna optimization
for thisFly = 1:NFlies
    if f.ft_debug
        disp(['Fly: ',num2str(thisFly)])
    end
    
    % get speed of the fly
    speedFly = smooth(getFlyDiffVel(f,thisFly),speedSmthLen);
    speedFly(isnan(getFlyDiffVel(f,thisFly))) = NaN;
    
    % points where mean speed (smoothed) is above the speed threshold
    thesePoints = speedFly'>f.immobile_speed*f.heading_allignment_factor;
    
    % get the speed allignment mask, true is not valid point
    [mask,~] = getSpeedAllignMask(f,thisFly,maskdilate);
    
    % find usefull frame numbers
    usefullFrames = find(thesePoints.*~mask);
    
    % get active frames, i.e. fly is assigned as active status = 1
    activeFrames = find(f.tracking_info.fly_status(thisFly,:)==1,1):find(f.tracking_info.fly_status(thisFly,:)==1,1,'last'); % first frame:last frame
    not_active_frames = 1:size(f.tracking_info.orientation,2);
    not_active_frames(activeFrames) = [];
    
    
    % if usefull frames is empty, therefore this track is either almost always
    % at the border, or motionless.
    if isempty(usefullFrames)
        if f.ft_debug
            disp('There not any usefull frames. Fly must be almost always at the border, or at rest')
        end
        %% find regions where fly is fully in the arena and free of interactions
        % and away from the borders
        maskpoints = find(~mask); % not interacting etc
        maskpoints(logical(sum(maskpoints==not_active_frames',1)))=[]; % ignore the points where the fly is lost
        
        % optimize antenna using f.length_aos_mat frames
        if length(maskpoints)<f.length_aos_mat
            if isempty(maskpoints)
                bad_flies(thisFly) = 1;
                disp('Could not find any good frames for antenna optimization')
                disp('mean of the good flies will be assigned to this')
            else
                if length(maskpoints)>=3
                    disp('There are at least 3 useful frames. Will use those')
                    f.antoffset(thisFly) = OptAntonTheseFrames(f,thisFly,maskpoints);
                    if isnan(f.antoffset(thisFly))
                        disp('There frames did not work out. Will use those average of good guys.')
                        bad_flies(thisFly) = 1;
                    end
                else
                    bad_flies(thisFly) = 1;
                    disp('Could not find any good frames for antenna optimization')
                    disp('mean of the good flies will be assigned to this')
                end
            end
        else
            disp(['There are at least ',num2str(f.length_aos_mat),' useful frames. Will use those'])
            f.antoffset(thisFly) = OptAntonTheseFrames(f,thisFly,maskpoints(1:f.length_aos_mat));
        end
        
    else % there are usefull frames for orientation heading allignment
        if f.ft_debug
            disp('There are some usefull frames where fly walks. Will use those for optimzation')
        end
        % optimize antenna using f.length_aos_mat frames
        if (length(usefullFrames)<f.length_aos_mat)
            if (length(usefullFrames)>=3)
                disp('There are at least 3 useful frames. Will use those')
                f.antoffset(thisFly) = OptAntonTheseFrames(f,thisFly,usefullFrames);
            else
                bad_flies(thisFly) = 1;
                disp('Could not find any good frames for antenna optimization')
                disp('mean of the good flies will be assigned to this')
            end
        else
            disp(['There are at least ',num2str(f.length_aos_mat),' useful frames. Will use those'])
            f.antoffset(thisFly) = OptAntonTheseFrames(f,thisFly,usefullFrames(1:f.length_aos_mat));
            if isnan(f.antoffset(thisFly))
                bad_flies(thisFly) = 1;
                disp('Could not find any good frames for antenna optimization')
                disp('mean of the good flies will be assigned to this')
            end
        end
        
        
        
    end
    
    
end

% get the mean of the all good flies and assign to bad flies
goodval = f.antoffset(1:NFlies);
goodval(logical(bad_flies)) = []; % remove bad fly values
f.antoffset(find(bad_flies)) = nanmean(goodval);

% double check the nan values
f.antoffset(isnan(f.antoffset)) = nanmean(goodval);

if f.ft_debug
    disp(['Orientation of all ',num2str(NFlies), ' flies are post processed...'])
end



