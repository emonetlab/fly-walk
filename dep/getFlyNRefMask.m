function [mask,maskPIV] = getFlyNRefMask(I,camera,diln,thresh,minObjSize)
%getFlyMask
% return a binary mask for the detected flies in the image I with threshold
% thres and dilation diln.

switch nargin
    case 4
        minObjSize = 100; % remove objects maller than this
    case 3
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
    case 2
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
        diln = 5; % dilate by disk size of 5
end
im = imbinarize(uint8(I),thresh);
im = bwareaopen(im, minObjSize);
S = regionprops(im,'PixelList','Centroid','Orientation','MajorAxisLength','MinorAxisLength');

pxllist = vertcat((S.PixelList));
Imask = zeros(size(I));

%% get reflections mask
confac = 0.957;

for Snum = 1:(numel(S))
    % get cordinates
    xrel = S(Snum).Centroid(1)-camera.x;
    yrel = S(Snum).Centroid(2)-camera.y;
    rho = sqrt(xrel^2+yrel^2)*confac; % the distance of ref relative to the camera
    theta = cart2pol(xrel,yrel);  % direction from camera to S center
    [xref1,xref2] = pol2cart(theta,rho);  % get ref postions relative to camera
    S(Snum).RX(1) = xref1 + camera.x;     % add cam offset
    S(Snum).RX(2) = xref2 + camera.y;     % add cam offset

    % major and minor axis
    S(Snum).RMaj = confac.*S(Snum).MajorAxisLength;
    S(Snum).RMin = confac.*S(Snum).MinorAxisLength;
    
    xymat_ref = ellips_matrix_reflections(S(Snum).RMin/2,S(Snum).RMaj/2,S(Snum).Orientation,S(Snum).RX(1),S(Snum).RX(2));
    
    pxllist = [pxllist;xymat_ref]; % accumullate
    
end

if ~isempty(pxllist)
    for j = 1:length(pxllist(:,2))
        Imask(pxllist(j,2),pxllist(j,1)) = 1;
    end
end

% dilate the mask and compare
se = strel('disk',diln);
mask = logical(imdilate(Imask,se));

%% get mask for PIV
im = imbinarize(uint8(mask)*255);
S = regionprops(im,'PixelList');

maskPIV = cell(numel(S),2);
for i = 1:numel(S)
    maskPIV{i,1} = S(i).PixelList(:,1);
    maskPIV{i,2} = S(i).PixelList(:,2);
end
