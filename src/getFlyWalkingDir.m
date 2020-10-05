function f = getFlyWalkingDir(f,thisFrame)
% returns the walking directions of flies estimated by calculating the
% vector angle between two consecutive fly position

if nargin==1
    thisFrame = f.current_frame;
end

if thisFrame==1
    return
end

current_assigned_flies = find(f.tracking_info.fly_status(:,thisFrame)==1);

current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,thisFrame)));...
    find(~isnan(f.tracking_info.overpassing(:,thisFrame)))];

% remove interacting flies
current_assigned_flies(logical(sum(current_assigned_flies==current_interacting_flies',2))) = [];

for flynum = 1:length(current_assigned_flies)
   
    thisFly = current_assigned_flies(flynum);
    
    % assign fly heading
    [vxy(1),vxy(2)] = getKalmanVelocity(f,thisFly,f.nPointsSpeedEstHeading,thisFrame);
    heading = mod(cart2pol(vxy(1),vxy(2))/pi*180,360); %degrees
    if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
        f.tracking_info.heading(thisFly,thisFrame) = heading;
%         if f.ft_debug
%             disp(['Heading calculated for fly #: ' num2str(thisFly)])
%         end
    else
        f.tracking_info.heading(thisFly,thisFrame) = f.tracking_info.heading(thisFly,thisFrame-1);
%         if f.ft_debug
%             disp(['Previous Heading is registered for fly #: ' num2str(thisFly)])
%         end
    end
end


