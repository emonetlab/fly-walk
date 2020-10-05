%% findReflections.m
% finds reflections for all flies in the current frame 
% 
function f = findReflections(f)



for i = 1:length(f.current_object_status)
	if f.current_object_status(i) > 0
		current_fly = f.current_object_status(i);
		F = [f.current_objects(i).Centroid(1) f.current_objects(i).Centroid(2)]; 
		C = f.camera_center;
		

		% get a profile along the radial line
		if f.use_gpu
			radial_profile = improfile(gather(f.current_raw_frame),[C(1) F(1)],[C(2) F(2)]);
		else
			radial_profile = improfile(f.current_raw_frame,[C(1) F(1)],[C(2) F(2)]);
		end

		ok = true;

		% blank out areas inside the camera radius
		if ceil(f.camera_radius) > length(radial_profile)
			% too short, skip
			ok = false;
		else
			radial_profile(1:ceil(f.camera_radius)) = NaN;
		end


		if length(radial_profile) > 50
			radial_profile = radial_profile(end-50+1:end);

			fly_angle = f.current_objects(i).Orientation;
			angle_to_camera = radtodeg(atan2((F(2) - C(2)),(C(1) - F(1))));
			cut_off  = .5*f.current_objects(i).MajorAxisLength*abs(cosd(angularDifference(fly_angle,angle_to_camera))) + .5*f.current_objects(i).MinorAxisLength*abs(sind(angularDifference(fly_angle,angle_to_camera)));
			cut_off = floor(cut_off);

			radial_profile(end-cut_off+1:end) = NaN;

			% make sure there are no flies anywhere close to the line
			x = nonnans(f.tracking_info.x(:,f.current_frame));
			y = nonnans(f.tracking_info.y(:,f.current_frame));
			rm_this = x == F(1);
			x(rm_this) = [];
			y(rm_this) = [];
			if min(distanceFromLineToPoint([C;F],[x y])) < 40
				ok = false;
			end
			

		end

		if ok
			try
				f.tracking_info.radial_profile(current_fly,:,f.current_frame) = radial_profile;
			catch
			end
		end

		% % it's impossible for a reflection to be more than 50px away from the fly
		% z = max([length(radial_profile)-50 1]);
		% radial_profile(1:z) = NaN;

		% blank out the fly figure out how far the ellipse of the fly body extends from the centroid along this line


		% % cut out brief blips; these may be caused by noise
		% temp = radial_profile > 40;
		% temp = filtfilt(ones(10,1),10,double(temp));
		% temp(temp<0.9) = 0; temp(temp>0) = 1;
		% temp = logical(temp);
		% radial_profile(~temp) = NaN;

		% if max(radial_profile) < 60
		% else
		% 	[p,loc] = findpeaks(radial_profile,'MinPeakWidth',2,'Npeaks',1,'MinPeakHeight',60);
		% 	if ~isempty(p)
		% 		f.tracking_info.reflection_peak_value(current_fly,f.current_frame) = p;
		% 		f.tracking_info.reflection_peak_location(current_fly,f.current_frame) = loc;
		% 	end
		% end


	end
end