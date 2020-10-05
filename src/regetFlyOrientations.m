function f = regetFlyOrientations(f)

if f.use_fly_intensity_gradient % use the intensity gradient along the fly to determine the direction
    
    % which flies are assigned
    current_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);

    current_interacting_flies = NaN;

    % reconntruct current objects
    f = reConstructCurrentObjetcs(f);

    % % contruct objects fronm the tracking info
    % [f.current_objects,f.current_object_status] = TrackInfo2Struct(f);

    % remove interacting flies
    current_assigned_flies(logical(sum(current_assigned_flies==current_interacting_flies',2))) = [];

    flies_with_object = intersect(f.current_object_status,current_assigned_flies);

    S = f.current_objects;


    for flynum = 1:length(flies_with_object)


        % assign fly heading
        [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstHeading);
        heading = mod(cart2pol(vxy(1),vxy(2))/pi*180,360); %degrees
        if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
            f.tracking_info.heading(flies_with_object(flynum),f.current_frame) = heading;
        else
            if ~f.current_frame==1
                f.tracking_info.heading(flies_with_object(flynum),f.current_frame) = f.tracking_info.heading(flies_with_object(flynum),f.current_frame-1);
            end
        end


        Stemp = S(f.current_object_status==flies_with_object(flynum));

        theta = getFlyGradOrientation(f,Stemp);
        
       
        % now calculate and assign the fly orientation
        if ~isempty(theta)
                f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = theta;

                % if there is more than maxAllowedTurnAngle jump between frames asign the previous
                if ~(f.current_frame==1)
                    if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,...
                                    f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi)>120/180*pi % if flipped orientation received
                        f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
                    elseif angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,...
                                    f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi)>f.maxAllowedTurnAngle % if grooming or something
                        if ~f.current_frame==1
                            f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1);
                        end
                    end
                end

%                 if isempty(getInteractions(f,flies_with_object(flynum)))
%                     [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstAllign);
%                     heading = mod(cart2pol(vxy(1),vxy(2)),2*pi);
%                     if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
%                         if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi,heading)>(2*pi/3)
%                             f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
%                             f.HeadNOrientAllign(flies_with_object(flynum)) = 1;
%                         end
%                     end
%                 end

        else % segments have same intensity, therefore direction cannot be determined
            if f.ft_debug
                disp(['fly number: ' num2str(flynum)])
                disp('The segments have same average intensity. We will use the computer generated direction.')
            end

            % if there is more than maxAllowedTurnAngle jump between frames asign the previous
            if ~f.current_frame==1
                if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,Stemp.Orientation)>120/180*pi % if flipped orientation received
                    f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(Stemp.Orientation+pi,2*pi)*180/pi;
                elseif angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,Stemp.Orientation)>f.maxAllowedTurnAngle % if grooming or something
                    if ~f.current_frame==1
                        f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1);
                    end
                else
                    f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(Stemp.Orientation*180/pi,360);
                end
            end


%             % if not alligned with the heading do it
%             if isempty(getInteractions(f,flies_with_object(flynum)))
%                 [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstAllign);
%                 heading = mod(cart2pol(vxy(1),vxy(2)),2*pi);
%                 if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
%                     if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi,heading)>2*pi/3
%                         f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
%                         f.HeadNOrientAllign(flies_with_object(flynum)) = 1;
%                     end
%                 end
%             end
        end

    end

else
    
end

