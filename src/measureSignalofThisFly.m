function f = measureSignalofThisFly(f,this_fly)
%measureSignalofThisFly
% creates virtual antenna and integrates the intensity
% over it and gets the mean value of the measurement. ignores interacting
% flies



% flies with reflections
only_these_refs = find(f.reflection_status(:,f.current_frame)==1);
pxllist = fillFliesNReflections(f,only_these_refs);

% get pxl list with all possible flies
pxllistAll = fillFliesNReflections(f);

if strcmp(f.antenna_type,'fixed')
    xymat_antenna = getAntPxlList(f,this_fly,'fixed');
    
    if isempty(xymat_antenna)
        return
    end
    
    if ~isempty(pxllist)
        % how much antenna overlaps
        f.tracking_info.antenna_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,pxllist,'rows'),1)/size(xymat_antenna,1);
        
    end
    
    if ~isempty(pxllistAll)
        % how much antenna overlaps with all possible reflections
        f.tracking_info.antenna1R_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,pxllistAll,'rows'),1)/size(xymat_antenna,1);
        
    end
    
    % secondary antenna of this fly
    if ~isempty(PredRefGeomFly(f,this_fly,2))
        srPxls = PredRefGeomFly(f,this_fly,2);
        f.tracking_info.antenna2R_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,srPxls,'rows'),1)/size(xymat_antenna,1);
        
    end
    
    % fixed antenna
    if isempty(xymat_antenna)
        f.tracking_info.signal(this_fly,f.current_frame) = NaN;
    else
        % get fluorescence on the antenna
        idx = sub2ind(size(f.current_raw_frame),xymat_antenna(:,2),xymat_antenna(:,1));
        if strcmp(f.signal_meas_method,'mean')
            f.tracking_info.signal(this_fly,f.current_frame) = mean(double((f.current_raw_frame(idx))));
        elseif strcmp(f.signal_meas_method,'median')
            if isfield(f.tracking_info,'signal_mean')
                f.tracking_info.signal_mean(this_fly,f.current_frame) = mean(double((f.current_raw_frame(idx))));
            end
            f.tracking_info.signal(this_fly,f.current_frame) = median(double((f.current_raw_frame(idx))));
        end
    end
    
elseif strcmp(f.antenna_type,'dynamic')
    xymat_antenna = getAntPxlList(f,this_fly,'dynamic');
    xymat_antfix = getAntPxlList(f,this_fly,'fixed'); % to see if 2R ever overlapped
    if isempty(xymat_antenna)
        return
    end
    
    if f.show_antenna ==2   % mask plot is requested
        figure(fig1)
        plot(xymat_antenna(:,1),xymat_antenna(:,2),'om');
    end
    
    if ~isempty(xymat_antenna)
        if ~isempty(pxllist)
            % how much antenna overlaps
            f.tracking_info.antenna_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,pxllist,'rows'),1)/size(xymat_antenna,1);
            
        end
        
        if ~isempty(pxllistAll)
            % how much antenna overlaps with all possible reflections
            f.tracking_info.antenna1R_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antenna,pxllistAll,'rows'),1)/size(xymat_antenna,1);
            
        end
    end
    
    if ~isempty(xymat_antfix)
        % secondary antenna of this fly
        if ~isempty(PredRefGeomFly(f,this_fly,2,f.R2Resize))
            srPxls = PredRefGeomFly(f,this_fly,2,f.R2Resize);
            f.tracking_info.antenna2R_overlap(this_fly,f.current_frame) =  size(intersect(xymat_antfix,srPxls,'rows'),1)/size(xymat_antfix,1);
            
        end
    end
    
    % dynamic antenna
    if isempty(xymat_antenna)
        f.tracking_info.signal(this_fly,f.current_frame) = NaN;
    else
        % get fluorescence on the antenna
        idx = sub2ind(size(f.current_raw_frame),xymat_antenna(:,2),xymat_antenna(:,1));
        if strcmp(f.signal_meas_method,'mean')
            f.tracking_info.signal(this_fly,f.current_frame) = mean(double((f.current_raw_frame(idx))));
        elseif strcmp(f.signal_meas_method,'median')
            if isfield(f.tracking_info,'signal_mean')
                f.tracking_info.signal_mean(this_fly,f.current_frame) = mean(double((f.current_raw_frame(idx))));
            end
            f.tracking_info.signal(this_fly,f.current_frame) = median(double((f.current_raw_frame(idx))));
        end
    end
    
end


