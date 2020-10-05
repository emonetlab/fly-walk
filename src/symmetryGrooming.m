function f = symmetryGrooming(f,threshold_lowVelocity,min_time,thres_meaningful)
% This function analyses the symmetry in the fly, and looks if the
% dispersion of the pixels around its central axix have a very different
% deviation. If that is the case, then a grooming behavior might be
% happening.
% The used dispersion measure is : Standard Distance Deviation.

% Grooming detection
f.tracking_info.groomSym.mask = zeros(size(f.tracking_info.signal));
f.tracking_info.groomSym.std_relationship = zeros(size(f.tracking_info.signal));
f.tracking_info.groomSym.std_relationship1 = zeros(size(f.tracking_info.signal));
f.tracking_info.groomSym.std_relationship2 = zeros(size(f.tracking_info.signal));
f.tracking_info.groomSym.perimeteter = zeros(size(f.tracking_info.signal));
f.tracking_info.groomSym.excent = zeros(size(f.tracking_info.signal));

f.track_movie=0;

f.current_frame=1;
f.operateOnFrame;

for thisframe = 1:f.nframes
    if isempty(find(f.tracking_info.fly_status(:,thisframe)==1, 1))
        continue
    end
    
    theseflies = find(f.tracking_info.fly_status(:,thisframe)==1);
    f.previous_frame = f.current_frame;
    f.current_frame=thisframe;
    f.operateOnFrame;
    S=getAllObjectsInFrame(f,[f.regionprops_args,{'Perimeter','Eccentricity'}]);
    disp(['frame:',num2str(f.current_frame),' ',num2str(numel(S)),' flies found'])
    
    for itergg = 1:length(theseflies)
        this_fly = theseflies(itergg);
        % First point for the major axis line:
        posx = f.tracking_info.x(this_fly,f.current_frame); %DO I SMOOTH THEM?
        posy = f.tracking_info.y(this_fly,f.current_frame); %DO I SMOOTH THEM?
        % Second point for the major axis line:
        angleFly= f.tracking_info.orientation(this_fly,f.current_frame)/180*pi;
        [xflys,yflys] = pol2cart(angleFly,f.tracking_info.majax(this_fly,f.current_frame));
        posx2 = posx + xflys;
        posy2 = posy + yflys;
%         [xflys,yflys] = pol2cart(angleFly+pi,f.tracking_info.majax(this_fly,f.current_frame));
%         posx = posx + xflys;
%         posy = posy + yflys;
        
        % Separate pixels to each side of the fly:
        % The line equation parameters:
        a = posy2 - posy;
        b = -(posx2 - posx);
        c = posx2.*posy - posy2.*posx;
        %% Iteration to find points at each side of the major axis: %%%%%%%%%%%%%%%%
        [vx,vy] = getKalmanVelocity(f,this_fly);
        spd = sqrt(vx^2+vy^2).*f.ExpParam.mm_per_px.*f.ExpParam.fps;
        if isnan(spd)
            spd = 0;
        end
        signalVeloc = spd; % Velocity signal.
        
        
        %%%% INEFFICIENT CODE :%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         img_now = read(vidobj,f.tracking_info.frameNum(iterMA));
        %         img_now = img_now(crpy,crpx) - imav;
        %         Iflies = im2bw(img_now,threshold_fl);
        % %         Iflies = bwareaopen(Iflies, minObjSize); % Get rid of noise.
        %         labflies = bwlabel(Iflies);
        %         lab_act = labflies(round(posy(iterMA)+1),round(posx(iterMA)+1));
        %         [row,col] = find(Iflies == lab_act);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%% WORKING DIRECTLY FROM THE LINE EQUATION :%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Getting the pixels position of the actual fly in the frame:
        pos=[S.Centroid];
        pos = reshape(pos,2,length(pos)/2);
        
        fly_pos_x = f.tracking_info.x(this_fly,f.current_frame);
        fly_pos_y = f.tracking_info.y(this_fly,f.current_frame);
        
        % estimate the distance vector
        dist_vec = sqrt((pos(1,:)-fly_pos_x).^2+(pos(2,:)-fly_pos_y).^2);
        
        % which ones fall in the criteria
        ObjectsNDistance = [(1:numel(S))',dist_vec'];
        
        % sort in ascending order
        ObjectsNDistance = sortrows(ObjectsNDistance,2);
        
        this_object = ObjectsNDistance(1);
        f.tracking_info.groomSym.perimeteter(this_fly,f.current_frame) = S(this_object).Perimeter;
        f.tracking_info.groomSym.excent(this_fly,f.current_frame) = S(this_object).Eccentricity;
        
        
        pixfly_xy = S(this_object).PixelList;
        col = pixfly_xy(:,1);
        row = pixfly_xy(:,2);
%         col = pixfly_xy(:,1)*f.ExpParam.mm_per_px;
%         row = pixfly_xy(:,2)*f.ExpParam.mm_per_px;
        % Flies which are below the line:
        %         v1 = [col - posx(iterMA),row - posy(iterMA)]';
        %         v2 = repmat([xflys(iterMA);xflys(iterMA)],1,size(v1,2));
        %         anglebt = atan2(v2(2,:)-v1(2,:),v2(1,:)-v1(1,:));
        indPixLn = a*col+b*row+c;
        % Distance of point to line:
        den = sqrt((a^2)+(b^2));
        % %         d_Oneside = abs(a(iterMA)*col(anglebt > 0)+b(iterMA)*row(anglebt > 0)+c(iterMA))/den;
        % %         d_Otherside = abs(a(iterMA)*col(anglebt < 0)+b(iterMA)*row(anglebt < 0)+c(iterMA))/den;
        d_Oneside2 = sqrt(((col(indPixLn > 0)-posx).^2)+((row(indPixLn > 0)+posy).^2));
        d_Otherside2 = sqrt(((col(indPixLn < 0)-posx).^2)+((row(indPixLn < 0)+posy).^2));
        d_Oneside1 = abs(a*col(indPixLn > 0)+b*row(indPixLn > 0)+c)/den;
        d_Otherside1 = abs(a*col(indPixLn < 0)+b*row(indPixLn < 0)+c)/den;
        d_Oneside = sum(indPixLn > 0);
        d_Otherside = sum(indPixLn < 0);
        % Getting the Standard Distance Deviation:
        std_Oneside = d_Oneside;%std(d_Oneside(:));
        std_Otherside = d_Otherside;%std(d_Otherside(:));
        std_Oneside1 = std(d_Oneside1(:));
        std_Otherside1 = std(d_Otherside1(:));
        std_Oneside2 = std(d_Oneside2(:));
        std_Otherside2 = std(d_Otherside2(:));
        
        if(isnan(std_Oneside)||isnan(std_Otherside)) % The fly is on the border of the frame
            std_relationship = 0;
        else
            if(max([std_Oneside,std_Otherside]) == 0)
                std_relationship = 0;
            else
                std_relationship = min([std_Oneside,std_Otherside]) / max([std_Oneside,std_Otherside]);
            end
        end
        if(isnan(std_Oneside1)||isnan(std_Otherside1)) % The fly is on the border of the frame
            std_relationship1 = 0;
        else
            if(max([std_Oneside1,std_Otherside1]) == 0)
                std_relationship1 = 0;
            else
                std_relationship1 = min([std_Oneside1,std_Otherside1]) / max([std_Oneside1,std_Otherside1]);
            end
        end
        if(isnan(std_Oneside2)||isnan(std_Otherside2)) % The fly is on the border of the frame
            std_relationship2 = 0;
        else
            if(max([std_Oneside2,std_Otherside2]) == 0)
                std_relationship2 = 0;
            else
                std_relationship2 = min([std_Oneside2,std_Otherside2]) / max([std_Oneside2,std_Otherside2]);
            end
        end
        
        f.tracking_info.groomSym.std_relationship(this_fly,f.current_frame) = std_relationship;
        f.tracking_info.groomSym.std_relationship1(this_fly,f.current_frame) = std_relationship1;
        f.tracking_info.groomSym.std_relationship2(this_fly,f.current_frame) = std_relationship2;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % %%%% WORKING ON THE FLY ROTATION :%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % % Form the rotation matrix
        %         R = [cos(angleFly(iterMA)) sin(angleFly(iterMA)); -sin(angleFly(iterMA)) cos(angleFly(iterMA))]; % From fly's coordinates to X-Y.
        %         invR = R'; % From X-Y to fly's coordinates.
        % % Converting frame coordinates to fly's coordinates:
        %         pixfly_xy = f.tracking_info.pixelsfly(iterMA).m;
        %         col = pixfly_xy(:,1)*mm_per_px - posx(iterMA);
        %         row = pixfly_xy(:,2)*mm_per_px - posy(iterMA);
        %         pxll_invR = invR*([col,row]'); % Convert from X-Y to fly's coordinates by rotation. (e.g. fly's major axis paralel to x axis).
        %         col = pxll_invR(1,:)';
        %         row = pxll_invR(2,:)';
        % % Distance of point to line:
        %         d_Oneside = sum(row > 0);%abs(row(row > 0));%
        %         d_Otherside = sum(row < 0);%abs(row(row < 0));%
        % % Getting the Standard Distance Deviation:
        %         std_Oneside = d_Oneside;%std(d_Oneside(:));%%
        %         std_Otherside = d_Otherside;%std(d_Otherside(:));%
        %
        %         if(isnan(std_Oneside)||isnan(std_Otherside)) % The fly is on the border of the frame
        %             std_relationship(iterMA) = 0;
        % %             contloco = contloco + 1
        %         else
        %             if(max([std_Oneside,std_Otherside]) == 0)
        %                 std_relationship(iterMA) = 0;
        %                 contloco = contloco + 1
        %             else
        %                 std_relationship(iterMA) = min([std_Oneside,std_Otherside]) / max([std_Oneside,std_Otherside]);
        %             end
        %         end
        %     end
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
end

tot_num_of_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');
%%%% PROCESSING THE GROOMING/ASYMMETRIC PRESENCE :%%%%%%%%%%%%%%%%%%%%%%%%%
for itergg = 1:tot_num_of_flies
    % Getting the envelope:
    signalRel = 1 -  f.tracking_info.groomSym.std_relationship2(itergg,:);
    signalRel = smooth(signalRel,3);
    signalRel = sqrt(smooth(signalRel.^2,12)); % Final Envelope.
    % Obtaining meaningful asymmetric changes:
    groomSymPres = signalRel > thres_meaningful;
    % Velocity analysis:
    mskgv = signalVeloc < threshold_lowVelocity;
    mskgv = imdilate(mskgv,strel('square',5));
    % Masking the asymmetric changes with the velocity:
    finalMaskSymVelc = mskgv.*groomSymPres;
    % Prunning of the spurious times:
    finalMaskSymVelc = bwareaopen(finalMaskSymVelc, floor(f.ExpParam.fps*min_time)); % Get rid of noise.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    f.tracking_info.groomSym.mask(itergg,:) = finalMaskSymVelc;
    
end


