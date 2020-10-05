function [mask,maskInt] = getSpeedAllignMask(f,thisFly,maskdilate)
% returns a mask for speed allignment. Value is true if any of the following
% conditions apply: periphery, collision, overpass and jump. The combined
% condition mask is dilated by maskdilate.
% Outputs:
%   mask: periphery + Collision + overpass + jump + lost fly status + NaN
%   orientation value + ignored interaction
%   maskInt: Collision + overpass + jump + lost fly status + ignored
%   interaction

if nargin<3
    maskdilate = 3;
end

% find ignored interactions
if isfield(f.tracking_info,'IgnoredInteractions')
    maskigint = f.tracking_info.IgnoredInteractions(thisFly,:)>0;
else
    f = findAllIgnoredInteractions(f);
    maskigint = f.tracking_info.IgnoredInteractions(thisFly,:)>0;
end

maskp = (f.tracking_info.periphery(thisFly,:)>0);
maskc = (abs(f.tracking_info.collision(thisFly,:))>0);
masko = (abs(f.tracking_info.overpassing(thisFly,:))>0);
maskj = (f.tracking_info.jump_status(thisFly,:)>0);
maskornan = isnan(f.tracking_info.orientation(thisFly,:));

% set lost and away mask after eliminating the parts lost at the end
lastActiveFrame = find(f.tracking_info.fly_status(thisFly,:)>1,1,'last'); % first frame:last frame
if f.tracking_info.fly_status(thisFly,lastActiveFrame)==2
    [pt,~] = getOnOffPoints(diff(f.tracking_info.fly_status(thisFly,:)==2));
    masklost = zeros(size(maskp));
    masklost(1:pt(end)) = f.tracking_info.fly_status(thisFly,1:pt(end))==2;
else
    masklost = f.tracking_info.fly_status(thisFly,:)==2;
end
if f.tracking_info.fly_status(thisFly,lastActiveFrame)==3
    [pt,~] = getOnOffPoints(diff(f.tracking_info.fly_status(thisFly,:)==3));
    maskaway = zeros(size(maskp));
    maskaway(1:pt(end)) = f.tracking_info.fly_status(thisFly,1:pt(end))==3;
else
    maskaway = f.tracking_info.fly_status(thisFly,:)==3;
end
mask = maskp + maskc + masko + maskigint + maskj + masklost + maskaway + maskornan;
maskInt = maskc + masko + maskigint + maskj + masklost + maskaway;

% binarize the mask
mask = mask>0;
maskInt = maskInt>0;

% dilate the mask
mask = imdilate(mask,strel('disk',maskdilate+1)); % dilate more to get usefull frame within the segment edges
maskInt = imdilate(maskInt,strel('disk',maskdilate));


