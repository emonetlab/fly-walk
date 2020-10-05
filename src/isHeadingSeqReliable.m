function status = isHeadingSeqReliable(heading,angle_flip_threshold)
% returns 1 if the heading sequence does not have direction flips, returns
% 0 otherwise

if nargin < 2
    angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
end

% copy the heading vector
headverify = heading;

% go over all and allign to the first
for i = 2:(length(heading))
    headverify(i) = AllignOrient2Ref(heading(i),heading(i-1),angle_flip_threshold);
end

% check the agreement
status = all(heading==headverify);