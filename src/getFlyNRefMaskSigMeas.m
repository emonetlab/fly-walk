function [mask,pxllist] = getFlyNRefMaskSigMeas(f,only_these_refs,diln)
%getFlyNRefMaskSigMeas
% return a binary mask for the detected flies and reflections. Includes
% reflections of only given flies

% get fly mask first
switch nargin
    case 2
        diln = 5;
    case 1
        diln = 5;
        only_these_refs = 'all';    % include all possible reflections in the mask
    case 0
        help fillFLies
        error('where is f?')
end

% get all pixel list
if ~isempty(f.current_objects)
    pxllist = vertcat((f.current_objects.PixelList));
else
    f = findAllObjectsInFrame(f);
    pxllist = vertcat((f.current_objects.PixelList));
end
% create a mask with enlarging the bounding boxes by 0.1 percent
Imask = zeros(size(f.current_raw_frame));

% if isempty(only_these_refs)
%     mask = Imask;
%     pxllist = [];
%     return
% end
    


%% get reflections mask
confac = 0.957;

% get the objects to be worked on
if isnumeric(only_these_refs)&&~isempty(only_these_refs)
    S = f.current_objects(logical(sum(f.current_object_status==only_these_refs',2)));
elseif strcmp(only_these_refs,'all')
    S = f.current_objects;
else 
    S = [];
end


for Snum = 1:(numel(S))
    % get cordinates
    xrel = S(Snum).Centroid(1)-f.ExpParam.camera.x;
    yrel = S(Snum).Centroid(2)-f.ExpParam.camera.y;
    rho = sqrt(xrel^2+yrel^2)*confac; % the distance of ref relative to the camera
    theta = cart2pol(xrel,yrel);  % direction from camera to S center
    [xref1,xref2] = pol2cart(theta,rho);  % get ref postions relative to camera
    S(Snum).RX(1) = xref1 + f.ExpParam.camera.x;     % add cam offset
    S(Snum).RX(2) = xref2 + f.ExpParam.camera.y;     % add cam offset

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
Sm = regionprops(mask,'PixelList');
pxllist = vertcat(Sm .PixelList);
