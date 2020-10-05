function f = reEstimateOrientations(f)
% reassigns the fly orientations. This function assumes the tracking is
% already done. Re-constructs the current objects

% disable tracking
f.track_movie=0;
% set heading allignment factor
f.heading_allignment_factor = 9;

% start from the first frame
f.current_frame=1;
f.operateOnFrame;

% initiate the gradient orientation collection anf flip indexes
f.tracking_info.OrientFlipind = zeros(size(f.tracking_info.x,1),1);
f.tracking_info.OrientLocked = zeros(size(f.tracking_info.x,1),1);

if strcmp(f.orientation_method,'Int Grad Vote')
    f.tracking_info.grador = zeros(size(f.tracking_info.x,1),f.nFramesforGradOrient);
    
    for thisframe = 1:f.nframes
        f.previous_frame = f.current_frame;
        f.current_frame = thisframe;
        f.operateOnFrame;
        
        f = GetCorrectNLockOrientations(f);
        
        if ~isempty(f.ui_handles)
            if ~isempty(f.ui_handles.fig)
                if f.show_annotation
                    % show tracking annotation
                    showTrackingAnnotation(f)
                end
            end
        end
    end
    
elseif strcmp(f.orientation_method,'Heading Lock')
    f.tracking_info.OrientVerify = zeros(size(f.tracking_info.x,1),f.HeadingAllignPointsNum+1); % container for orientation - walking direction verification
    % extra point is for checking the end of verification
    
    for thisframe = 1:f.nframes
        f.previous_frame = f.current_frame;
        f.current_frame = thisframe;
        % set all oerientations to gradient orientation for start
        f = getAllFlyGradOrs(f);
        disp(['frame: ',num2str(thisframe)])
        
        f = GetCorrectNLockOrientations(f);
        f.operateOnFrame;
        
    end
elseif strcmp(f.orientation_method,'Heading Allign')
    for thisframe = 1:f.nframes
        f.previous_frame = f.current_frame;
        f.current_frame = thisframe;
        f.operateOnFrame;
        
        f = getFlyOrientations(f);
        if ~isempty(f.ui_handles)
            if ~isempty(f.ui_handles.fig)
                if f.show_annotation
                    % show tracking annotation
                    showTrackingAnnotation(f)
                end
            end
        end
        
    end
    
end




