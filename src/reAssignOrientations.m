function f = reAssignOrientations(f)
% reassigns the fly orientations. This function assumes the tracking is
% already done. Re-constructs the current objects


f.track_movie=0;

f.current_frame=1;
f.operateOnFrame;
f.tracking_info.grador = zeros(size(f.tracking_info.x,1),f.nFramesforGradOrient);

for thisframe = 1:f.nframes
    f.previous_frame = f.current_frame;
    f.current_frame = thisframe;
    f.operateOnFrame;
    f = regetFlyOrientations(f);
    if ~isempty(f.ui_handles)
        if ~isempty(f.ui_handles.fig)
            if f.show_annotation
                % show tracking annotation
                showTrackingAnnotation(f)
            end
        end
    end
end




