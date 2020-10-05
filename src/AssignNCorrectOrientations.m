function f = AssignNCorrectOrientations(f)
% corrects orientation flips. determines the reliable direction from a list
% of gradient orientations of the fly intensity


if strcmp(f.orientation_method,'Int Grad Vote')
    % collect orientations by intensity gradient estimate
    % check angle sifferences, find the least flipping angle and set that
    % as the correct orientation
    
    
    % which flies are assigned now
    assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    
    for flynum = 1:length(assigned_flies)
        
        % first check with previous and flip if necessary
        f = checkNflipOrientation(f,assigned_flies(flynum));
        
        % is the orientation locked (i.e. verified and corrected)
        if f.tracking_info.OrientLocked(assigned_flies(flynum))==0 % not locked
            
            % check if we reached the state of making a decision for correct angle
            if ~(f.tracking_info.grador(assigned_flies(flynum),end)==0)&&(~getFlyInteractJumpStatus(f,assigned_flies(flynum))) % yes, all orientations are logged, see if there is any reliable orientation
                trueind = find((abs(angleDiffVec(f.tracking_info.grador(assigned_flies(flynum),:)))>0).*(abs(angleDiffVec(f.tracking_info.grador(assigned_flies(flynum),:)))<30))+1;
                if isempty(trueind) % the angle collection is not reliable
                    % register the angle as it is and restart the collection
                    f.tracking_info.grador(assigned_flies(flynum),:) = 0;
                else
                    % yes there is one reliable orientation
                    genind = f.current_frame-(f.nFramesforGradOrient-trueind(1));
                    % we found a reliable orientation. correct previous ones,
                    % lock and change the state
                    if f.tracking_info.orientation(assigned_flies(flynum),genind)==f.tracking_info.grador(assigned_flies(flynum),trueind(1))
                        % the verified oerientation is same as the registered
                        % one. no need to make a flip
                    else
                        % all previous orientation are wrong, flip them all
                        flipind = f.tracking_info.OrientFlipind(assigned_flies(flynum));
                        f.tracking_info.orientation(assigned_flies(flynum),flipind:f.current_frame) = ...
                            mod(f.tracking_info.orientation(assigned_flies(flynum),flipind:f.current_frame)+180,360);
                        % and now lock the angle
                        f.tracking_info.OrientLocked(assigned_flies(flynum)) = 1;
                        if f.ft_debug
                            disp(['Orientation Locked, Fly: ',mat2str(assigned_flies(flynum))])
                        end
                    end
                end
            else % we still need to collect angles untill all requested ones are logged
                % now just cused the previous one for correction, which you
                % already did
            end
        end
    end
    
    
elseif strcmp(f.orientation_method,'Heading Lock')
    % In this method:
    % 1- do not bother gradent measurement. Use the orientation provided by
    % the regionprops
    % 2- set all orientations to initial orientation
    % 3- when fly starts to walk i.e speed > f.immobile_speed*heading_allignment_factor
    % allign the orientation and lock it with the heading
    % 4_ check and verify the allignment f.HeadingAllignPointsNum times
    % repeat 2-3 after any interaction, jump or newly entering fly
    % which flies are assigned now
    assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    
    for flynum = 1:length(assigned_flies)
        
        % first check with previous and flip if necessary
        f = checkNflipOrientation(f,assigned_flies(flynum));
        
        % get interaction and jump state
        
        % is the orientation locked (i.e. verified and corrected)
        if (f.tracking_info.OrientLocked(assigned_flies(flynum))==0) % not locked
            
            % check if we reached the state of making a decision for correct angle
            if isAtKalmanAlligmentSpeed(f,assigned_flies(flynum))&&(~getFlyInteractJumpStatus(f,assigned_flies(flynum))) % yes, the fly has a speed above the decision threshold
                % check with the heading and flip to correct orientation if necessary
                this_orientation = f.tracking_info.orientation(assigned_flies(flynum),f.current_frame); % degrees
                heading = getAllignmentHeadingKalman(f,assigned_flies(flynum)); % degrees
                if (angleBWorientations(this_orientation/180*pi,heading/180*pi)/pi*180)>120 % opposite alligment, flip it
                    flipind = f.tracking_info.OrientFlipind(assigned_flies(flynum));
                    f.tracking_info.orientation(assigned_flies(flynum),flipind:f.current_frame) = ...
                        mod(f.tracking_info.orientation(assigned_flies(flynum),flipind:f.current_frame)+180,360);
                    f.tracking_info.OrientLocked(assigned_flies(flynum)) = 1; % lock the allignment
                    if f.ft_debug
                        disp(['Orientation is flipped & Locked, Fly: ',mat2str(assigned_flies(flynum))])
                    end
                else % no need to flip, the allignment is correct, just lock it
                    f.tracking_info.OrientLocked(assigned_flies(flynum)) = 1; % lock the allignment
                    if f.ft_debug
                        disp(['Orientation is correct! Locked, Fly: ',mat2str(assigned_flies(flynum))])
                    end
                end
            end
        else %orientation is locked, now measure several times and verify
            % how many times is it verified
            verify_ind = find(f.tracking_info.OrientVerify(assigned_flies(flynum),:)==0,1);
            if verify_ind<f.HeadingAllignPointsNum
                % is current speed above threshold
                if isAtKalmanAlligmentSpeed(f,assigned_flies(flynum))&&(~getFlyInteractJumpStatus(f,assigned_flies(flynum))) % yes, the fly has a speed above the decision threshold
                    this_orientation = f.tracking_info.orientation(assigned_flies(flynum),f.current_frame); % degrees
                    heading = getAllignmentHeadingKalman(f,assigned_flies(flynum)); % degrees
                    if (angleBWorientations(this_orientation/180*pi,heading/180*pi)/pi*180)>120 % opposite alligment, unlock, reset values
                        f.tracking_info.OrientLocked(assigned_flies(flynum)) = 0; % unlock the allignment
                        f.tracking_info.OrientVerify(assigned_flies(flynum),:) = 0;
                    else % correct allignment
                        f.tracking_info.OrientVerify(assigned_flies(flynum),verify_ind) = 1;
                    end
                end
            elseif verify_ind==f.HeadingAllignPointsNum
                % is current speed above threshold
                if isAtKalmanAlligmentSpeed(f,assigned_flies(flynum))&&(~getFlyInteractJumpStatus(f,assigned_flies(flynum))) % yes, the fly has a speed above the decision threshold
                    this_orientation = f.tracking_info.orientation(assigned_flies(flynum),f.current_frame); % degrees
                    heading = getAllignmentHeadingKalman(f,assigned_flies(flynum)); % degrees
                    if (angleBWorientations(this_orientation/180*pi,heading/180*pi)/pi*180)>120 % opposite alligment, unlock, reset values
                        f.tracking_info.OrientLocked(assigned_flies(flynum)) = 0; % unlock the allignment
                        f.tracking_info.OrientVerify(assigned_flies(flynum),:) = 0;
                    else % correct allignment
                        f.tracking_info.OrientVerify(assigned_flies(flynum),verify_ind) = 1;
                        if f.ft_debug
                            disp(['Orientation is verified! Fly: ',mat2str(assigned_flies(flynum))])
                        end
                    end
                end
            end
                        
                        
        end
    end
    
end
