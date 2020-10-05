function mask = getFlyMask(I,diln,thresh,minObjSize)
%getFlyMask
% return a binary mask for the detected flies in the image I with threshold
% thres and dilation diln.

switch nargin
    case 3
        minObjSize = 100; % remove objects maller than this
    case 2
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
    case 1
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
        diln = 5; % dilate by disk size of 5
end
im = imbinarize(uint8(I),thresh);
im = bwareaopen(im, minObjSize);
S = regionprops(im,'PixelList');

% create a mask with enlarging the bounding boxes by 0.1 percent
Imask = zeros(size(I));
pxllist = vertcat((S.PixelList));
if ~isempty(pxllist)
    for j = 1:length(pxllist(:,2))
        Imask(pxllist(j,2),pxllist(j,1)) = 1;
    end
end

% dilate the mask and compare
se = strel('disk',diln);
mask = logical(imdilate(Imask,se));
