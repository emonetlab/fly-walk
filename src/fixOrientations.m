%% fixOrientations.m
% fixes orientations of objects in the frame
% operates on a flyWalk object
% this function assumes that every object is a fly
% and attempts to find the end that is the head. it assumes that the head is brighter than the tail
% 
function f = fixOrientations(f)

% unpack data
r = f.current_objects;

for i = 1:length(r)
	temp = cutImage(f.current_raw_frame',r(i).Centroid,20)';

	% rotate the image so that the fly is aligned to the Y axis
	temp = imrotate(temp',r(i).Orientation,'nearest','crop');
	temp = max(temp(:,20:21)'); % pixel values along midline

	% find when the values leave saturation at either end
	left_m = mean(temp(max([1,find(temp==255,1,'first')-5]):find(temp==255,1,'first')-1));
	right_m = mean(temp(find(temp==255,1,'last'):min(find(temp==255,1,'last')+5,41)));

	if left_m > right_m
		% fly oriented correctly
	else
		% flip it
		r(i).Orientation = r(i).Orientation + 180;
	end

end