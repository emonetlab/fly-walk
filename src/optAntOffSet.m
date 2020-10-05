function antoffset = optAntOffSet(f,this_fly,pxllist)
%optAntOffSet
% optimizes the antenna offset by:
% overlap: minimizing the overlap and distance, then averages all
% optimized offset values over all requested frames. For flies with antenna
% completely overlapping with another fly, and interacting flies the
% average value of other flies is set.
% signal: virtual antenna is moved back and forth until getting the closet
% distance to fly and minimum median signal in the virtual antenna

xc= f.tracking_info.x(this_fly,f.current_frame);
yc= f.tracking_info.y(this_fly,f.current_frame);
Theta =  f.tracking_info.orientation(this_fly,f.current_frame)/180*pi; % convert to radian

%%%%%%% ANTENNA PARAMETERS
%generate coordinates for antenna
ant_maj = f.tracking_info.minax(this_fly,f.current_frame)/f.antlen;
ant_min = f.tracking_info.minax(this_fly,f.current_frame)/f.antwd;
ant_ornt = Theta + pi/2;

if any(isnan([ant_maj,ant_min,ant_ornt]))||any([isempty(ant_maj),isempty(ant_min),isempty(ant_ornt)])
    if f.ft_debug
        disp(['fly: ',num2str(this_fly),' reappeared from lost state. Skipping this.'])
    end
    antoffset = NaN;
    return
end

if strcmp(f.antenna_opt_method,'overlap')
    % optimize by minimizing the overlap between dilated fly and the
    % virtual antenna
    
    iter = 1;
    optimized = 0;
    tolerance = 1e-4;
    offmin = f.antoffset_lim(1);
    offmax = f.antoffset_lim(2);
    offval = (offmin+offmax)/2;
    
    while (iter<100)&&~optimized
        x_ant = xc + f.tracking_info.majax(this_fly,f.current_frame).*offval.*cos(Theta);
        y_ant = yc + f.tracking_info.majax(this_fly,f.current_frame).*offval.*sin(Theta);
        
        if strcmp(f.antenna_shape,'box')
            ang = -f.tracking_info.orientation(this_fly,f.current_frame)+90;
            xymat_antenna = getBoxAntennaPixels(f,this_fly,x_ant,y_ant,ang);
        else
            % generate the pixel list for antenna location
            xymat_antenna = getShapePixels(f,ant_min,ant_maj,ant_ornt,x_ant,y_ant);
            % antpxls = ellips_mat_aneq(ant_min,ant_maj,ant_ornt,x_ant,y_ant);
        end
        
        % clean the bad pixels
        [imyl,imxl]=size(f.current_raw_frame); % image limits
        xymat_antenna(xymat_antenna(:,2)<1,:)=[];
        xymat_antenna(xymat_antenna(:,1)<1,:)=[];
        xymat_antenna(xymat_antenna(:,2)>imyl,:)=[];
        xymat_antenna(xymat_antenna(:,1)>imxl,:)=[];
        
        % how much antenna overlaps
        if size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)==0
            offvalt = offval;
            offmax = offval;
            offval = (offmin+offmax)/2;
        else
            offvalt = offval;
            offmin = offval;
            offval = (offmin+offmax)/2;
        end
        if (abs(offvalt-offval)<=tolerance)&&((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1))==0)
            optimized = 1;
            if f.ft_debug
                disp(['fly: ',num2str(this_fly),' antoffset is optimized in ',num2str(iter), ' iterations. antoffset = ',num2str(offval),...
                    ' overlap = ',num2str((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1)))])
            end
        end
        iter = iter + 1;
        if iter == 100
            if f.ft_debug
                disp(['After 100 iterations fly: ',num2str(this_fly),' antoffset is estimated as antoffset = ',num2str(offval),...
                    ' overlap = ',num2str((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1)))])
            end
        end
    end
    
    antoffset = offval;
    if (size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1))==1
        % antenna totally overlaps
        if f.ft_debug
            disp(['fly: ',num2str(this_fly),' has a completely overlapping antenna. Skipping this.'])
        end
        antoffset = NaN;
    end
    
elseif strcmp(f.antenna_opt_method,'signal')
    % did not code for this yet
    keyboard
    % optimize by minimizing the measured intensity in the virtual antenna
    
    iter = 1;
    optimized = 0;
    tolerance = 1e-4;
    offmin = f.antoffset_lim(1);
    offmax = f.antoffset_lim(2);
    offval = (offmin+offmax)/2;
    
    while (iter<100)&&~optimized
        x_ant = xc + f.tracking_info.majax(this_fly,f.current_frame).*offval.*cos(Theta);
        y_ant = yc + f.tracking_info.majax(this_fly,f.current_frame).*offval.*sin(Theta);
        
        % generate the pixel list for antenna location
        if strcmp(f.antenna_shape,'box')
            ang = -f.tracking_info.orientation(this_fly,f.current_frame)+90;
            xymat_antenna = getBoxAntennaPixels(f,this_fly,x_ant,y_ant,ang);
        else
            xymat_antenna = getShapePixels(f,ant_min,ant_maj,ant_ornt,x_ant,y_ant);
        end

        
        % clean the bad pixels
        [imyl,imxl]=size(f.current_raw_frame); % image limits
        xymat_antenna(xymat_antenna(:,2)<1,:)=[];
        xymat_antenna(xymat_antenna(:,1)<1,:)=[];
        xymat_antenna(xymat_antenna(:,2)>imyl,:)=[];
        xymat_antenna(xymat_antenna(:,1)>imxl,:)=[];
        
        % does antenna overlaps
        if size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)==0
            offvalt = offval;
            offmax = offval;
            offval = (offmin+offmax)/2;
        else
            offvalt = offval;
            offmin = offval;
            offval = (offmin+offmax)/2;
        end
        if (abs(offvalt-offval)<=tolerance)&&((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1))==0)
            optimized = 1;
            if f.ft_debug
                disp(['fly: ',num2str(this_fly),' antoffset is optimized in ',num2str(iter), ' iterations. antoffset = ',num2str(offval),...
                    ' overlap = ',num2str((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1)))])
            end
        end
        iter = iter + 1;
        if iter == 100
            if f.ft_debug
                disp(['After 100 iterations fly: ',num2str(this_fly),' antoffset is estimated as antoffset = ',num2str(offval),...
                    ' overlap = ',num2str((size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1)))])
            end
        end
    end
    
    antoffset = offval;
    if (size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1))==1
        % antenna totally overlaps
        if f.ft_debug
            disp(['fly: ',num2str(this_fly),' has a completely overlapping antenna. Skipping this.'])
        end
        antoffset = NaN;
    end
    
end