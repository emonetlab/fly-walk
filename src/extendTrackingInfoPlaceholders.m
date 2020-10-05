% this function operates on a flyTrack object
% and expands the space for the tracking info if needed

function f = extendTrackingInfoPlaceholders(f)

% get the current size
currentTrackingInfoSize = size(f.tracking_info.fly_status,1);
maxtn = f.trackingInfoExtensionFactor*currentTrackingInfoSize;

 if f.ft_debug
     disp(' ')
     disp('----------------------------------------------------------------')
     disp(' ')
     disp(['Alloacted tracking info space is used. Now extending it ',num2str(f.trackingInfoExtensionFactor),' times'])
     disp(' ')
     disp('----------------------------------------------------------------')
     disp(' ')
 end


tracking_info = f.tracking_info;
% extend the placeholders
tracking_info.x(currentTrackingInfoSize+1:maxtn,:) = nan; % we budget for extra flies we might run into
tracking_info.y(currentTrackingInfoSize+1:maxtn,:) = nan;
tracking_info.heading(currentTrackingInfoSize+1:maxtn,:) = nan;
tracking_info.orientation(currentTrackingInfoSize+1:maxtn,:) = nan;
tracking_info.area(currentTrackingInfoSize+1:maxtn,:) = nan;
tracking_info.collision(currentTrackingInfoSize+1:maxtn,:) = nan; % id of the fly collided with
tracking_info.IgnoredInteractions(currentTrackingInfoSize+1:maxtn,:) = nan; % ignored interactions
tracking_info.overpassing(currentTrackingInfoSize+1:maxtn,:) = nan; % id of the fly collided with
tracking_info.fly_status(currentTrackingInfoSize+1:maxtn,:) = 0; % fly status, assigned or not, etc
tracking_info.periphery(currentTrackingInfoSize+1:maxtn,:) = 0; % whether or not the fly is in the periphery
tracking_info.error_code(currentTrackingInfoSize+1:maxtn,:) = int8(0);   % error code info
tracking_info.majax(currentTrackingInfoSize+1:maxtn,:) = nan; % major axis
tracking_info.minax(currentTrackingInfoSize+1:maxtn,:) = nan; % major axis
tracking_info.signal(currentTrackingInfoSize+1:maxtn,:) = nan; % signal measurement over the virtual antenna
tracking_info.BoxSignalPxl(:,:,currentTrackingInfoSize+1:maxtn) = nan; % box signal measurement over the fly
tracking_info.antoffsetAF(currentTrackingInfoSize+1:maxtn,:) = f.antenna_offset_default;
tracking_info.grador(currentTrackingInfoSize+1:maxtn,:) = 0; % container for orientations obtained by intensity gradient
tracking_info.OrientFlipind(currentTrackingInfoSize+1:maxtn,:) = 0; % index container for orientation flips
tracking_info.OrientLocked(currentTrackingInfoSize+1:maxtn,:) = 0; % logical for orientation lock to one particular direction
tracking_info.OrientVerify(currentTrackingInfoSize+1:maxtn,:) = 0; % container for orientation - walking direction verification
                                                                                          % extra point is for checking the end of verification

tracking_info.perimeter(currentTrackingInfoSize+1:maxtn,:) = nan; % major axis
tracking_info.excent(currentTrackingInfoSize+1:maxtn,:) = nan; % major axis

tracking_info.jump_status(currentTrackingInfoSize+1:maxtn,:) = false; % no reflections assumed in the beginning
tracking_info.antenna_overlap(currentTrackingInfoSize+1:maxtn,:) = 0; % virtual antenna overlap with another fly or primary reflection
tracking_info.antenna2R_overlap(currentTrackingInfoSize+1:maxtn,:) = 0; % virtual antenna overlap with secondary reflection;
tracking_info.antenna1R_overlap(currentTrackingInfoSize+1:maxtn,:) = 0; % virtual antenna overlap with secondary reflection;
% 0 -- unassigned, 
% 1 -- asssigned, visible
% 2 -- assigned, missing
% 3 -- assigned, missing at the border, terminate the tracks
% 4 -- lost in the interaction, dropped after a certain time
% -1 -- assigned, possibly colliding with one object
% -2 -- assigned, possibly colliding with two objects
% -11 -- assigned, missing in the frame probably overpassing

% re-assign the tracking info
f.tracking_info = tracking_info;


% reflection variables
f.reflection_status(currentTrackingInfoSize+1:maxtn,:) = false; % no reflections assumed in the beginning
f.reflection_meas(currentTrackingInfoSize+1:maxtn,:) = nan; %store reflection measurements
f.reflection_overlap(currentTrackingInfoSize+1:maxtn,:) = 0; %store reflection overlaps
f.HeadNOrientAllign(currentTrackingInfoSize+1:maxtn,:) = 0; % is heading and orientration alligned
f.antoffset(currentTrackingInfoSize+1:maxtn,:) = f.antenna_offset_default; % antenna ofset parameter (default value)
f.antoffset_opt_mat(currentTrackingInfoSize+1:maxtn,:) = nan; % antenna ofset parameter             
f.antoffset_status(currentTrackingInfoSize+1:maxtn,:) = 0; % antenna ofset parameter


