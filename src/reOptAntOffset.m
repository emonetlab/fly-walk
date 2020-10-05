function f = reOptAntOffset(f)
%reOptAntOffset(f)
% for all given frames, in each frame estimates the optimized antenna
% offset by:
% overlap: minimizing the overlap and distance, then averages all
% optimized offset values over all requested frames. For flies with antenna
% completely overlapping with another fly, and interacting flies the
% average value of other flies is set.
% signal: virtual antenna is moved back and forth until getting the closet
% distance to fly and minimum median signal in the virtual antenna

% reset the antenna status
f.antoffset_status = zeros(size(f.antoffset_status));

% reset optimize mat
f.antoffset_opt_mat = NaN(size(f.antoffset_opt_mat));

% last registered fly
registered_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');
for flynum = 1:registered_flies
    these_frames = find(f.tracking_info.fly_status(flynum,:)==1);
    delx = diff(f.tracking_info.x(flynum,these_frames));
    dely = diff(f.tracking_info.y(flynum,these_frames));
    this_speed = sqrt(delx.^2+dely.^2);
    frame_ind = find(this_speed>(f.immobile_speed*f.heading_allignment_factor*2),1);
    if isempty(frame_ind)
        continue
    end
   while (~f.antoffset_status(flynum))&&(frame_ind<=length(these_frames))
       f.previous_frame = f.current_frame;
       f.current_frame = these_frames(frame_ind);
       
       f.operateOnFrame;
%        [vxy(1),vxy(2)] = getKalmanVelocity(f,flynum,f.nPointsSpeedEstHeading);
%        if (((sqrt(vxy(1)^2+vxy(2)^2))>f.immobile_speed*f.heading_allignment_factor*2))&&...
%                (~f.tracking_info.jump_status(flynum,f.current_frame))
       if (~f.tracking_info.jump_status(flynum,f.current_frame))
            % get the pxl list for dilated flies
            pxllist = fillFliesNReflections(f,[],f.antenna_opt_dil_n); % dilate n times
            valind = find(isnan(f.antoffset_opt_mat(flynum,:)),1);
            val = optAntOffSet(f,flynum,pxllist);
            if ~isnan(val)
                f.antoffset_opt_mat(flynum,valind) = val;
                f.antoffset(flynum) = nanmean(f.antoffset_opt_mat(flynum,:));
                if valind == f.length_aos_mat
                    f.antoffset_status(flynum) = 1;
                end
            end
       end
       frame_ind = frame_ind + 1;
   end
end

% set the non-optimized ones to mean value
f.antoffset(f.antoffset_status(1:registered_flies)==0) = mean((f.antoffset(f.antoffset_status(1:registered_flies)==1)));
