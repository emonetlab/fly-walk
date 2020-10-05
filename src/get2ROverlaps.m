function f = get2ROverlaps(f)
%get2ROverlap
% calculates the overlap between the virtual antenna and the secondary
% reflection of that fly

% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
if isempty(current_flies)
    return
end


% go over these flies and measure the signal
for flynum = 1:length(current_flies)
     this_fly = current_flies(flynum);
     xc= f.tracking_info.x(this_fly,f.current_frame);
     yc= f.tracking_info.y(this_fly,f.current_frame);
     Theta =  f.tracking_info.orientation(this_fly,f.current_frame)/180*pi;
     if isnan(Theta)
         continue
     end
     antoffset = f.antoffset(this_fly);
    
     %%%%%%% ANTENNA PARAMETERS
     %generate coordinates for antenna
     ant_maj = f.tracking_info.minax(this_fly,f.current_frame)/f.antlen;
     ant_min = f.tracking_info.minax(this_fly,f.current_frame)/f.antwd;
     ant_ornt = Theta + pi/2;
     x_ant = xc + f.tracking_info.majax(this_fly,f.current_frame).*antoffset.*cos(Theta);
     y_ant = yc + f.tracking_info.majax(this_fly,f.current_frame).*antoffset.*sin(Theta);
     if isnan(ant_min)
         f.tracking_info.error_code(this_fly,f.current_frame) = 6;
         continue
     end
     % generate the pixel list for antenna location
     xymat_antenna = ellips_mat_aneq(ant_min,ant_maj,ant_ornt,x_ant,y_ant);

     % clean the bad pixels
     [imyl,imxl]=size(f.current_raw_frame); % image limits
     xymat_antenna(xymat_antenna(:,2)<1,:)=[];
     xymat_antenna(xymat_antenna(:,1)<1,:)=[];
     xymat_antenna(xymat_antenna(:,2)>imyl,:)=[];
     xymat_antenna(xymat_antenna(:,1)>imxl,:)=[];
     
     % secondary antenna of this fly
     if ~isempty(PredRefGeomFly(f,this_fly,2))
         f.tracking_info.antenna2R_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,PredRefGeomFly(f,this_fly,2),'rows'),1)/size(xymat_antenna,1);     
     end

end

        

