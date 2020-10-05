%% removeFliesFromMedianFrame
% removes flies from the median frame
% this serves to remove flies from the median frame that we subtract from every frame
% so it handles cases when the fly is very still (especially in the beginning). 
%

function f = removeFliesFromMedianFrame(f)
	
	% find all objects in the median frame	
	raw_image = f.median_frame;
	raw_image(raw_image<f.fly_body_threshold) = 0;
	L = logical(raw_image);
	r = regionprops(L,'Centroid','PixelIdxList','Area');

	% remove very small objects as they might be noise
	r([r.Area]<f.min_fly_area) = [];

	% only consider objects a certain distance from the edges
	s = fliplr(size(f.median_frame));

	rm_this = false(length(r),1);
	for i = 1:length(r)
		if r(i).Centroid(1) < f.edge_cutoff
			rm_this(i) = true;
		end
		if r(i).Centroid(2) < f.edge_cutoff
			rm_this(i) = true;
		end
		if r(i).Centroid(1) + f.edge_cutoff > s(1)
			rm_this(i) = true;
		end
		if r(i).Centroid(2) + f.edge_cutoff > s(2)
			rm_this(i) = true;
		end
		if r(i).Area > 300
			rm_this(i) = true;
		end
	end
	r(rm_this) = [];

	mask = false(s(2),s(1));
	for i = 1:length(r)
		mask(r(i).PixelIdxList) = true;
	end

	mask = imdilate(mask,strel('disk',10));
	f.median_frame = regionfill(f.median_frame,mask);


end