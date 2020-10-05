function status = getHeadingOrientAllignStatus(heading,orientation,angle_flip_threshold)
% returns a logical for the given sequence. 1: if orientation si alligned
% to heading, 0 if not

if nargin < 3
    angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
end

% copy the heading vector
orientverify = orientation;

% go over all and allign to the first
for i = 1:(length(heading))
    orientverify(i) = AllignOrient2Ref(orientation(i),heading(i),angle_flip_threshold);
end

% check the agreement
status = (orientation==orientverify);