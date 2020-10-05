function f = getFlyOrientations(f)


% im = imbinarize(uint8(f.current_raw_frame),f.fly_body_threshold/255);
% im = bwareaopen(im,f.min_fly_area);
%//Perform regionprops and get the shapes
% S = regionprops(im,'Centroid', 'Orientation', 'MajorAxisLength', 'MinorAxisLength','PixelList','Area');


current_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);

% current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
%     find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];

current_interacting_flies = NaN;

% remove interacting flies
current_assigned_flies(logical(sum(current_assigned_flies==current_interacting_flies',2))) = [];

flies_with_object = intersect(f.current_object_status,current_assigned_flies);

% flies_with_no_object = [setdiff(current_assigned_flies,flies_with_object);...
%     current_interacting_flies];

S = f.current_objects;

if f.showpieces
        h2 = figure;
        h1 = figure;
        plotEllipseData_1(S,f.current_raw_frame); 
        axis equal;
        hax1 = gca;
        hold on;
end 

for flynum = 1:length(flies_with_object)
    
    % assign fly heading
    [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstHeading);
    heading = mod(cart2pol(vxy(1),vxy(2))/pi*180,360); %degrees
    if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
        f.tracking_info.heading(flies_with_object(flynum),f.current_frame) = heading;
    else
        f.tracking_info.heading(flies_with_object(flynum),f.current_frame) = f.tracking_info.heading(flies_with_object(flynum),f.current_frame-1);
    end
    
    
    Stemp = S(f.current_object_status==flies_with_object(flynum));
    
%     if flynum==16
%         keyboard
%     end
    % fix orientation between 0 and 180
    Stemp.Orientation = mod(Stemp.Orientation,360)*pi/180; %radians
    
        
    % obtain center position of the fly
        xc= Stemp.Centroid(1);
        yc= Stemp.Centroid(2);
        
        % convert angle into radian
        theta = Stemp.Orientation;
        
        % form the rotation matrix
        R = [ cos(theta) sin(theta);...
             -sin(theta) cos(theta)];
         
         % for the inverse rotation matrix
         invR = [ cos(theta) -sin(theta);...
                  sin(theta)  cos(theta)];

         %use the pixel list from fly props
         pxllist = Stemp.PixelList;
         
         if isempty(pxllist)
             f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1);
             continue
         end
         
         
         % pre-allocate memory for zero centered fly
         pxllist0 = zeros(size(pxllist));
        

         % take the fly to origin, prepare for inverse rotation
         pxllist0(:,1) = pxllist(:,1) - round(xc);
         pxllist0(:,2) = pxllist(:,2) - round(yc);
        
         % inverse rotate the centroid. make its major axis paralel to x
         % axis
         pxll_invR = invR*pxllist0';
         pxll_invR = pxll_invR';

        % determine the unique x indexes
        C = unique(pxll_invR(:,1)); %C = A(ia) and A = C(ic).
       
        % get segment indices
        segmentx = round(linspace(min(C),max(C),f.n_of_segments+1));
        
       
        % initiate segment, fluorescence, and xlocation matrics and cell arrays
        xymatseg = cell(f.n_of_segments,1);
        fluoseg = zeros(f.n_of_segments,1);
        xseg = zeros(f.n_of_segments,1);

        % go over segments and measure the mean fluoresces
        for i= 1: f.n_of_segments
            
            % get pixel matrix to temporary memory
            tempmat = pxll_invR;
            
            % delete the pixels falling out of the segment
            tempmat(tempmat(:,1)<segmentx(i),:)=[];
            tempmat(tempmat(:,1)>segmentx(i+1),:)=[];
            
            % re-rotate the segment and orient it with fly
            temprot = R*tempmat';
            
            % add the offset so that the segment falls on the fly
            tempmatrot = zeros(size(temprot))';
            tempmatrot(:,1) = round(temprot(1,:) + xc)';
            tempmatrot(:,2) = round(temprot(2,:) + yc)';
            
            % store segment pixel list
            xymatseg{i} = tempmatrot;
            if (sum(tempmatrot(:,1)==0)>0)||sum(tempmatrot(:,2)==0)>0
                if f.ft_debug
                    disp(['zero index calculated','. Fly: ', num2str(flynum), '. Segment: ', num2str(i),'. Xbar: ', num2str(mean(tempmatrot(:,1))), '. Ybar: ', num2str(num2str(mean(tempmatrot(:,2))))])
                end
                tempmatrot(tempmatrot(:,2)==0,:)=[];
                tempmatrot(tempmatrot(:,1)==0,:)=[];
                if f.ft_debug
                    disp('cleaned zeros')
                end
            end

            
            % measure the mean fluorescence on the segment
            fluoseg(i) = fluo_of_ellips_mask(tempmatrot,f.current_raw_frame);
            
            % what is the center x location of the segment
            xseg(i) = mean(tempmatrot(:,1));
            
            % if selected plot segments on the flies
            if f.showpieces==1
                figure(h1)
                plot(hax1,tempmatrot(:,1),tempmatrot(:,2),'o')
            end
            
        end
        
        if f.showpieces==1
            figure(h2);
            [r,c]=getrc_subplot((numel(S)));
            subplot(r,c,flynum)
            plot(xseg,fluoseg,'o--k',[xc xc],[min(fluoseg) max(fluoseg)],'r')
            xlabel('pxl')
            ylabel('mean fluo. int.')
            segnum = find(fluoseg==min(fluoseg));
            if numel(segnum)==1
                pnt = [xc-mean(xymatseg{segnum}(:,1)),yc-mean(xymatseg{segnum}(:,2))];
                [THETA,~] = cart2pol(pnt(1),pnt(2)); % radians
                title(['fly#: ', num2str(flynum),' \theta; ',num2str(mod(THETA/pi*180,360),'%5.0f'),' deg'])
            else
                title(['fly#: ', num2str(flynum)])
            end
        end
        
    % now calculate and assign the fly orientation
    segnum = find(fluoseg==min(fluoseg));
    if numel(segnum)==1
            pnt = [xc-mean(xymatseg{segnum}(:,1)),yc-mean(xymatseg{segnum}(:,2))];
            [THETA,~] = cart2pol(pnt(1),pnt(2)); % radians
            
            f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(THETA/pi*180,360);
            
%             % assign the orientation close to the gradient estimate
%             if angleBWorientations(Stemp.Orientation,THETA)>f.maxAllowedTurnAngle
%                 f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(Stemp.Orientation+pi,2*pi)*180/pi;
%             else                
%                 f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = Stemp.Orientation*180/pi;
%             end
            
            % if there is more than pi/2 jump between frames asign the previous
            if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,...
                            f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi)>f.maxAllowedTurnAngle
                f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
            end
            
            % if not alligned with the heading do it
            last_interaction_point = max(find(~isnan(f.tracking_info.collision(flies_with_object(flynum),1:f.current_frame)),1,'last'),...
                find(~isnan(f.tracking_info.overpassing(flies_with_object(flynum),1:f.current_frame)),1,'last'));
            if isempty(last_interaction_point)
                last_interaction_point = 1;
            end
                
%             if ~f.HeadNOrientAllign(flies_with_object(flynum))&&f.current_frame>(last_interaction_point+f.nPointsSpeedEstAllign)
            if (f.current_frame>(last_interaction_point+f.nPointsSpeedEstAllign))&&~f.tracking_info.jump_status(flies_with_object(flynum),f.current_frame)
                [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstAllign);
                heading = mod(cart2pol(vxy(1),vxy(2)),2*pi);
                if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
                    if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi,heading)>(2*pi/3)
                        f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
                        f.HeadNOrientAllign(flies_with_object(flynum)) = 1;
                    end
                end
            end
            
    else
        if f.ft_debug
            disp(['fly number: ' num2str(flynum)])
            disp('The segments have same average intensity. We will use the computer generated direction.')
        end
        
        % if there is more than pi/2 jump between frames asign the previous
        if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame-1)/180*pi,Stemp.Orientation)>f.maxAllowedTurnAngle
            f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(Stemp.Orientation+pi,2*pi)*180/pi;
        else
            f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(Stemp.Orientation*180/pi,360);
        end
        
        % if not alligned with the heading do it
        last_interaction_point = max(find(~isnan(f.tracking_info.collision(flies_with_object(flynum),1:f.current_frame)),1,'last'),...
            find(~isnan(f.tracking_info.overpassing(flies_with_object(flynum),1:f.current_frame)),1,'last'));
        if isempty(last_interaction_point)
            last_interaction_point = 1;
        end
        
        % if not alligned with the heading do it
%         if ~f.HeadNOrientAllign(flies_with_object(flynum))&&f.current_frame>(last_interaction_point+f.nPointsSpeedEstAllign)
        if (f.current_frame>(last_interaction_point+f.nPointsSpeedEstAllign))&&~f.tracking_info.jump_status(flies_with_object(flynum),f.current_frame)
            [vxy(1),vxy(2)] = getKalmanVelocity(f,flies_with_object(flynum),f.nPointsSpeedEstAllign);
            heading = mod(cart2pol(vxy(1),vxy(2)),2*pi);
            if sqrt(vxy(1)^2+vxy(2)^2)>f.immobile_speed*f.heading_allignment_factor
                if angleBWorientations(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)/180*pi,heading)>2*pi/3
                    f.tracking_info.orientation(flies_with_object(flynum),f.current_frame) = mod(f.tracking_info.orientation(flies_with_object(flynum),f.current_frame)+180,360);
                    f.HeadNOrientAllign(flies_with_object(flynum)) = 1;
                end
            end
        end
    end
    
end


% f.tracking_info.orientation(flies_with_no_object,f.current_frame) = f.tracking_info.orientation(flies_with_no_object,f.current_frame-1);
% f.tracking_info.heading(flies_with_no_object,f.current_frame) = f.tracking_info.heading(flies_with_no_object,f.current_frame-1); 
% f.tracking_info.orientation(flies_with_no_object,f.current_frame) = f.tracking_info.orientation(flies_with_no_object,f.current_frame-1);
% f.tracking_info.heading(flies_with_no_object,f.current_frame) = f.tracking_info.heading(flies_with_no_object,f.current_frame-1); 

% reset the allignment
% f.HeadNOrientAllign(flies_with_no_object) = 0;

