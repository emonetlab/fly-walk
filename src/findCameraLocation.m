%% findCameraLocation
% finds the location of the camera based on its reflection in the image
% this works by fitting a circle to the camera and finding the centre of that circle
% this function operates on a flyWalk object
% 
function f = findCameraLocation(f)

% grab the raw frame
I = f.current_raw_frame;
I(~f.mask) = 0;

assert(isa(I,'uint8'),'Expected raw frame to be a 8-bit image.')

% remove flies, clean up...
I = I - mean(nonzeros(I));
I(I>100) = 0;
I = imadjust(I);

% binarise and fill holes
I = im2bw(I);
I = imerode(I,strel('disk',5));
I = imfill(I,'holes');

I = imerode(I,strel('disk',5));

% find circles using hough transform
[centers,radii] = imfindcircles(I,[40 80]);

if length(radii) > 1
	[~,pick_me] = max(radii);
else
	pick_me = 1;
end
f.camera_center = centers(pick_me,:);
f.camera_radius = radii(pick_me);