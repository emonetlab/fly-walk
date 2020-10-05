function f = getSignalMeasurements(f)
%getSignalMeasurements
% creates virtual antenna and integrates the intensity
% over it and gets the mean value of the measurement. ignores interacting
% flies

% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
if isempty(current_flies)
    return
end

% which of these are interacting
current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
    find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];

% remove interacting flies
current_flies(logical(sum(current_flies==current_interacting_flies',2))) = [];

% flies with reflections
only_these_refs = find(f.reflection_status(:,f.current_frame)==1);

if f.show_antenna ==2   % mask plot is requested
    fig1 = setFigure;
    [pxllist,mask,~] = fillFliesNReflections(f,only_these_refs);
    imagesc(f.current_raw_frame+(mask)*10)
    axis image tight
    hold on
else
    pxllist = fillFliesNReflections(f,only_these_refs);
end

% get pxl list with all possible flies
pxllistAll = fillFliesNReflections(f);

if strcmp(f.antenna_type,'fixed')
    % go over these flies and measure the signal
    for flynum = 1:length(current_flies)
        this_fly = current_flies(flynum);
        xymat_antenna = getAntPxlList(f,this_fly,'fixed');
        
        if isempty(xymat_antenna)
            continue
        end
        
        if f.show_antenna ==2   % mask plot is requested
            figure(fig1)
            plot(xymat_antenna(:,1),xymat_antenna(:,2),'om');
        end
        
        if ~isempty(pxllist)
            % how much antenna overlaps
            f.tracking_info.antenna_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1);

        end
        
        if ~isempty(pxllistAll)
            % how much antenna overlaps with all possible reflections
            f.tracking_info.antenna1R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna(:,1:2),pxllistAll,'rows'),1)/size(xymat_antenna,1);

        end
        
        % secondary antenna of this fly
        if ~isempty(PredRefGeomFly(f,current_flies(flynum),2))
            srPxls = PredRefGeomFly(f,current_flies(flynum),2);
            f.tracking_info.antenna2R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna(:,1:2),srPxls,'rows'),1)/size(xymat_antenna,1);

        end
        
        % fixed antenna
        if isempty(xymat_antenna)
            f.tracking_info.signal(current_flies(flynum),f.current_frame) = NaN;
        else
            % get fluorescence on the antenna
            idx = sub2ind(size(f.current_raw_frame),xymat_antenna(:,2),xymat_antenna(:,1));
            if strcmp(f.signal_meas_method,'mean')
                f.tracking_info.signal(current_flies(flynum),f.current_frame) = mean(double((f.current_raw_frame(idx))));
            elseif strcmp(f.signal_meas_method,'median')
                if isfield(f.tracking_info,'signal_mean')
                    f.tracking_info.signal_mean(current_flies(flynum),f.current_frame) = mean(double((f.current_raw_frame(idx))));
                end
                f.tracking_info.signal(current_flies(flynum),f.current_frame) = median(double((f.current_raw_frame(idx))));
            end
            % if box antenna is requested measure segments and register
            % values
            if strcmp(f.antenna_shape,'box')
                AntBoxSignal = getAntennaBoxSignal(f,current_flies(flynum));
                f.tracking_info.AntBoxSignal(1:length(AntBoxSignal),current_flies(flynum),f.current_frame) = AntBoxSignal;
                pfitcoeffs = polyfit((1:length(AntBoxSignal))',AntBoxSignal,1);
                f.tracking_info.AntBoxSignalSlope(current_flies(flynum),f.current_frame) = pfitcoeffs(1);
            end
        end
        
        
    end
           
    
    
elseif strcmp(f.antenna_type,'dynamic')
    % go over these flies and measure the signal
    for flynum = 1:length(current_flies)
        this_fly = current_flies(flynum);
        xymat_antenna = getAntPxlList(f,this_fly,'dynamic');
        xymat_antfix = getAntPxlList(f,this_fly,'fixed'); % to see if 2R ever overlapped
        
        if f.show_antenna ==2   % mask plot is requested
            figure(fig1)
            plot(xymat_antenna(:,1),xymat_antenna(:,2),'om');
        end
        
        if ~isempty(xymat_antenna)
            if ~isempty(pxllist)
                % how much antenna overlaps
                f.tracking_info.antenna_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna(:,1:2),pxllist,'rows'),1)/size(xymat_antenna,1);

            end

            if ~isempty(pxllistAll)
                % how much antenna overlaps with all possible reflections
                f.tracking_info.antenna1R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna(:,1:2),pxllistAll,'rows'),1)/size(xymat_antenna,1);

            end
        end
        
        if ~isempty(xymat_antfix)
            % secondary antenna of this fly
            if ~isempty(PredRefGeomFly(f,current_flies(flynum),2,f.R2Resize))
                srPxls = PredRefGeomFly(f,current_flies(flynum),2,f.R2Resize);
                f.tracking_info.antenna2R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antfix(:,1:2),srPxls,'rows'),1)/size(xymat_antfix,1);

            end
        end
        
        % dynamic antenna
        if isempty(xymat_antenna)
            f.tracking_info.signal(current_flies(flynum),f.current_frame) = NaN;
        else
            % get fluorescence on the antenna
            idx = sub2ind(size(f.current_raw_frame),xymat_antenna(:,2),xymat_antenna(:,1));
            if strcmp(f.signal_meas_method,'mean')
                f.tracking_info.signal(current_flies(flynum),f.current_frame) = mean(double((f.current_raw_frame(idx))));
            elseif strcmp(f.signal_meas_method,'median')
                if isfield(f.tracking_info,'signal_mean')
                    f.tracking_info.signal_mean(current_flies(flynum),f.current_frame) = mean(double((f.current_raw_frame(idx))));
                end
                f.tracking_info.signal(current_flies(flynum),f.current_frame) = median(double((f.current_raw_frame(idx))));
            end
            % if box antenna is requested measure segments and register
            % values
            if strcmp(f.antenna_shape,'box')
                AntBoxSignal = getAntennaBoxSignal(f,current_flies(flynum));
                f.tracking_info.AntBoxSignal(1:length(AntBoxSignal),current_flies(flynum),f.current_frame) = AntBoxSignal;
                pfitcoeffs = polyfit((1:length(AntBoxSignal))',AntBoxSignal,1);
                f.tracking_info.AntBoxSignalSlope(current_flies(flynum),f.current_frame) = pfitcoeffs(1);
            end
        end
        
        
    end
    
end
% % write the measured signal to signal measurement matrix
% f.tracking_info.(['signal_',f.antenna_shape,'_',f.antenna_type])(:,f.current_frame)  = f.tracking_info.signal(:,f.current_frame);


