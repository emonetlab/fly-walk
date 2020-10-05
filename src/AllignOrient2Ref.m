function orientation = AllignOrient2Ref(orientation,reference,angle_flip_threshold)
% checks if the orientation is alligned to reference orientation. If the
% nagle between orientations is larger than angle_flip_threshold then flips
% the orientation

% groom_angle_threshold
groom_angle_threshold = 75;
if nargin < 3
    angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
end

angleBWO = angleBWorientations(orientation/180*pi,reference/180*pi)/pi*180;
if (angleBWO>angle_flip_threshold) && (angleBWO<(360-angle_flip_threshold))
    % there is direction flip. Correct it
    orientation = mod(orientation + 180,360);
elseif (angleBWO>groom_angle_threshold) && (angleBWO<(360-groom_angle_threshold))
    orientation = reference;
end