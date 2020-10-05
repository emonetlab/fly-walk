function f = getGroomMask(f,k,stdfactor,dilate_time)
% generates a grooming mask. Perimeter of the fly is filtered by a moving
% standard deviation filter. The excursions in the moving standard
% deviation above std of it times a factor are considered as grroming
% points. These points are set to 1 and dilated by 2 second window to
% cover fly sitting still during grooming. The size of the moving average
% window os 200 ms by default. Ignores the excursions lasting less than 2
% points

switch nargin
    case 3
        dilate_time = 2;    % seconds, dilate the mask
    case 2
        dilate_time = 2;    % seconds, dilate the mask
        stdfactor = .6; % value for thresholding: movstd>stdfactor*std(movstd)
    case 1
        dilate_time = 2;    % seconds, dilate the mask
        stdfactor = .6; % value for thresholding: movstd>stdfactor*std(movstd)
        k = 0.2; % sec
end

% convert k to points
k=round(k*f.ExpParam.fps);

nof_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');
f.tracking_info.groom_mask = zeros(size(f.tracking_info.signal));

for n = 1:nof_flies
    
    maskofsignal = f.tracking_info.mask_of_signal(n,:);
    perim = f.tracking_info.perimeter(n,:);
    cleanperim = f.tracking_info.perimeter(n,:);
    cleanperim(~maskofsignal) = [];
    perimth = (movstd(perim,k))>(stdfactor.*std(cleanperim));
    [onp,offp] = getOnOffPoints(diff(perimth));
    lenonoff = offp-onp;
    maskdilate = round(f.ExpParam.fps*dilate_time);
    % ignore if length is just 1
    mask = perimth;
    for j = 1:length(onp)
        if lenonoff(j)<2
            mask(onp(j):offp(j)) = 0;
        end
    end
    mask = mask>0;
    mask = imdilate(mask,strel('disk',maskdilate));
    f.tracking_info.groom_mask(n,:) = mask;

end
