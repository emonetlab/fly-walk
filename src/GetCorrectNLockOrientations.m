function f = GetCorrectNLockOrientations(f)
% determines the intensity gradient along each fly, estimates a reliable
% orientation by accumulating f.nFramesforGradOrient orientations for each
% fly, and locks the orientation to that one. Does not allow turns more
% than f.maxAllowedTurnAngle degrees.
% Operates on the current frame
% 

% which flies are assigned now
assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);

% set the flip index of these flies if they have just started
f.tracking_info.OrientFlipind(assigned_flies(f.tracking_info.OrientFlipind(assigned_flies)==0)) = f.current_frame;

% collect interacting flies
jumping_flies = find(f.tracking_info.jump_status(:,f.current_frame));
colliding_flies = find(~isnan(f.tracking_info.collision(:,f.current_frame)));
overpassing_flies = find(~isnan(f.tracking_info.overpassing(:,f.current_frame)));
periphery_flies = find(f.tracking_info.periphery(:,f.current_frame));
reset_these =[jumping_flies;colliding_flies;overpassing_flies;periphery_flies];
% remove flies that left the arena
reset_these = reset_these(logical(sum(reset_these==assigned_flies',2)));

if ~isempty(reset_these)
    % reset the flip start index for alligned but interacting, jumping etc flies
    f.tracking_info.OrientFlipind(reset_these(f.tracking_info.OrientLocked(reset_these)>0)) = f.current_frame;
    
    % unlock the orientation
    f.tracking_info.OrientLocked(reset_these) = 0;
    if strcmp(f.orientation_method,'Heading Lock')
        f.tracking_info.OrientVerify(reset_these,:) = 0;
    elseif strcmp(f.orientation_method,'Int Grad Vote')
        f.tracking_info.grador(reset_these,:) = 0;
    end
end

% get all fly orientations
f = getAllFlyOrientations(f);

% correct and assign, if reached to verification state lock the orientation
f = AssignNCorrectOrientations(f);