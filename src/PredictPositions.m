function split_objects = PredictPositions(f,resolve_these,which_object_overlaps)
% PredictPositions. Estimates the current positions of the flies using the
% previous positions, mean spedd and acceleration. Speeds up the flies if
% they are miving in opposite direction in order to better resolution
%

if f.ft_debug
    disp('Splitting methods did not work. I will predict the locations based on previous speed')
end

% resolve these flies
resolve_these = abs(resolve_these);

% initiate the splitted objects
split_objects(length(resolve_these),1).Area = [];

% % the first fly is the object that overlaps
% which_object_overlaps = find(f.current_object_status==resolve_these(1));

% speed vectors
v_resolve_these = zeros(length(resolve_these),2); 

% go over the flies one by one and estimate the locations
for i = 1:length(resolve_these)
    resolve_this = resolve_these(i);
    % determine what speed up to use
    [v_resolve_these(i,1),v_resolve_these(i,2)] = getKalmanVelocity(f,resolve_this);
end

v_resolve_these(isnan(v_resolve_these))=0; % set any non number to zero, assume stationary

% calculate the angle between speed vectors of these
% two collidign objects, firt and last objects. up to 3 flies 1. and last
% are overlapping guys
angle = acos(sum(v_resolve_these(end,:).*v_resolve_these(1,:))/norm(v_resolve_these(end,:))/norm(v_resolve_these(1,:)));

if angle<pi/2
    % they move in similar paralel directions. use
    % slower speed to resolve better
    sudc_ind = 1;
    if f.ft_debug
        disp(['Apperently flies: ',mat2str([resolve_these(1),resolve_these(end)]),' move along. Angle: ',num2str(angle,'%1.1f'), ' radians. Continue...'])
    end
else
    % they move in opposite directions. use higher
    % speed to shoot quickly to other side
    sudc_ind = 2;
    if f.ft_debug
        disp(['Apperently flies: ',mat2str([resolve_these(1),resolve_these(end)]),' move away. Angle: ',num2str(angle,'%1.1f'), ' radians. Speed Up.'])
    end
end

% if one of the objects is immobile, use faster speed
% anyway
immobl = isImmobile(f,resolve_these);
if any(immobl)
    sudc_ind = 1;
end


% estimate the predicted locations
for i = 1:length(resolve_these)
    resolve_this = resolve_these(i);
    if immobl(i)
        if f.ft_debug
            disp(['Apperently collision with the immobile fly: ',num2str(resolve_this)] )
        end
        f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1);
        f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1);
    else

        f.tracking_info.x(resolve_this,f.current_frame) = f.tracking_info.x(resolve_this,f.current_frame-1)+v_resolve_these(i,1)*f.speed_up_during_coll(sudc_ind);
        f.tracking_info.y(resolve_this,f.current_frame) = f.tracking_info.y(resolve_this,f.current_frame-1)+v_resolve_these(i,2)*f.speed_up_during_coll(sudc_ind);

        % bound this object by the box
        xy =   [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)]; 
        % get the closest point in the list
        xy = boundbyPxls(xy,f.current_objects(which_object_overlaps).PixelList);
        f.tracking_info.x(resolve_this,f.current_frame) = xy(1);
        f.tracking_info.y(resolve_this,f.current_frame) = xy(2);

    end

    % make 2 new imaginary objects and delete the overlapping guy
    split_objects(i).Area = NaN;
    split_objects(i).Centroid = [f.tracking_info.x(resolve_this,f.current_frame),f.tracking_info.y(resolve_this,f.current_frame)];
    split_objects(i).MajorAxisLength = NaN; % assume average major length
    split_objects(i).MinorAxisLength = NaN; % assume average minor length
    split_objects(i).Orientation = NaN;

    % label other fly as missing too, and overlapping
    f.tracking_info.fly_status(resolve_this,f.current_frame) = 2;
end
    

if f.ft_debug
    disp('Interacting flies are handled by predicting the locations.')
    disp('   ')
end
