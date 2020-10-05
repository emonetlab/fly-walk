%% findStimulus.m
% finds the stimulus, and determines if flies are within the stimulus or not
% 

function f = findStimulus(f)


s = fliplr(size(f.current_raw_frame));
% mask = imdilate(mask,strel('disk',10));
smoke = f.current_raw_frame;
flies = imdilate(smoke>f.fly_body_threshold,strel('disk',10));
smoke(logical(flies)) = 0;
smoke(smoke < f.min_stim_intensity) = 0;
smoke = imerode(logical(smoke),strel('disk',2,8));
smoke = imdilate(smoke,strel('disk',3));
r = regionprops(smoke,'MajorAxis','PixelIdxList');
r([r.MajorAxisLength]<f.min_stim_plume_length) = [];

mask = false(s(2),s(1));
for i = 1:length(r)
	mask(r(i).PixelIdxList) = true;
end

f.stimulus = mask;