function f = showFlyOrientations(f)
% plots arrows on flies indicating its direction. red: bottomsurface,
% green: tp surface

if isempty(f.ui_handles)
    return
end

if ~f.show_orientations
    % hide headings
    if  f.heading_hidden
    else
        hide_these_flies = 1:length(f.tracking_info.fly_status(:,f.previous_frame));
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.headings(hide_these_flies(flynum)).XData = NaN;
            f.plot_handles.headings(hide_these_flies(flynum)).YData = NaN;
        end
    end
    % hide orientations
    if  f.orientation_hidden
    else
        hide_these_flies = 1:length(f.tracking_info.fly_status(:,f.previous_frame));
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.orientations(hide_these_flies(flynum)).XData = NaN;
            f.plot_handles.orientations(hide_these_flies(flynum)).YData = NaN;
        end
        f.orientation_hidden =1;
    end
    return
end

if f.current_frame==1
    return
end


if f.show_orientations ==1 % show only orientations
    f.orientation_hidden = 0;
    % hide all headings if not hidden
    if  f.heading_hidden
    else
        hide_these_flies = 1:length(f.tracking_info.fly_status(:,f.previous_frame));
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.headings(hide_these_flies(flynum)).XData = NaN;
            f.plot_handles.headings(hide_these_flies(flynum)).YData = NaN;
        end
        f.heading_hidden =1;
    end
    show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
    for flynum = 1:length(show_these_flies)
           
            XY = getTriangleFlyOrient(f,show_these_flies(flynum));
            f.plot_handles.orientations(show_these_flies(flynum)).XData = XY(:,1);
            f.plot_handles.orientations(show_these_flies(flynum)).YData = XY(:,2);
            if f.reflection_status(show_these_flies(flynum),f.current_frame)
                f.plot_handles.orientations(show_these_flies(flynum)).Color = 'g';  
            else
                f.plot_handles.orientations(show_these_flies(flynum)).Color = 'k';  
            end
    end
    for flynum = 1:length(hide_these_flies)
        f.plot_handles.orientations(hide_these_flies(flynum)).XData = NaN;
        f.plot_handles.orientations(hide_these_flies(flynum)).YData = NaN;
    end


elseif f.show_orientations ==2 % show only headings
    f.heading_hidden = 0;
    % hide all headings if not hidden
    if  f.orientation_hidden
    else
        hide_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.orientations(hide_these_flies(flynum)).XData = NaN;
            f.plot_handles.orientations(hide_these_flies(flynum)).YData = NaN;
        end
        f.orientation_hidden =1;
    end
    show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
    for flynum = 1:length(show_these_flies)
            XY = getTriangleFlyHeading(f,show_these_flies(flynum));
            f.plot_handles.headings(show_these_flies(flynum)).XData = XY(:,1);
            f.plot_handles.headings(show_these_flies(flynum)).YData = XY(:,2);
%             if f.reflection_status(show_these_flies(flynum),f.current_frame)
%                 f.plot_handles.orientations(show_these_flies(flynum)).Color = 'g';  
%             else
%                 f.plot_handles.orientations(show_these_flies(flynum)).Color = 'k';  
%             end
    end
    for flynum = 1:length(hide_these_flies)
        f.plot_handles.headings(hide_these_flies(flynum)).XData = NaN;
        f.plot_handles.headings(hide_these_flies(flynum)).YData = NaN;
    end
elseif f.show_orientations ==3 % show both
    f.heading_hidden = 0;
    f.orientation_hidden = 0;
    show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
    for flynum = 1:length(show_these_flies)        

            XYH = getTriangleFlyHeading(f,show_these_flies(flynum));
            XYO = getTriangleFlyOrient(f,show_these_flies(flynum));

            % orientation
            f.plot_handles.orientations(show_these_flies(flynum)).XData = XYO(:,1);
            f.plot_handles.orientations(show_these_flies(flynum)).YData = XYO(:,2);
            if f.reflection_status(show_these_flies(flynum),f.current_frame)
                f.plot_handles.orientations(show_these_flies(flynum)).Color = 'g';  
            else
                f.plot_handles.orientations(show_these_flies(flynum)).Color = 'k';  
            end

            % heading
            f.plot_handles.headings(show_these_flies(flynum)).XData = XYH(:,1);
            f.plot_handles.headings(show_these_flies(flynum)).YData = XYH(:,2);
    end
    for flynum = 1:length(hide_these_flies)
        f.plot_handles.orientations(hide_these_flies(flynum)).XData = NaN;
        f.plot_handles.orientations(hide_these_flies(flynum)).YData = NaN;
        f.plot_handles.headings(hide_these_flies(flynum)).XData = NaN;
        f.plot_handles.headings(hide_these_flies(flynum)).YData = NaN;
    end
end

