function f = showFlies(f)

% show objects

% try
% 	delete(f.plot_handles.current_objects)
% catch
% end
%
% try
% 	for i = 1:length(f.plot_handles.fly_positions)
% 		f.plot_handles.fly_positions(i).XData = NaN;
% 	end
% 	temp = (reshape([f.current_objects.Centroid],2,length(f.current_objects)));
% 	f.plot_handles.current_objects = plot(temp(1,:),temp(2,:),'ro');
% catch
% end

if isempty(f.ui_handles)
    return
end

if isempty(f.tracking_info.fly_status)
    return
end 

if f.mark_flies
    f.fly_markers_hidden = 0;
    show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    if f.current_frame~=1
        hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
        %         hide_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)~=1);
    else
        hide_these_flies = [];
    end
    for flynum = 1:length(show_these_flies)
        f.plot_handles.fly_markers(show_these_flies(flynum)).Marker = 'o';
        f.plot_handles.fly_markers(show_these_flies(flynum)).XData = f.tracking_info.x(show_these_flies(flynum),f.current_frame);
        f.plot_handles.fly_markers(show_these_flies(flynum)).YData = f.tracking_info.y(show_these_flies(flynum),f.current_frame);
    end
    for flynum = 1:length(hide_these_flies)
        f.plot_handles.fly_markers(hide_these_flies(flynum)).XData = NaN;
        f.plot_handles.fly_markers(hide_these_flies(flynum)).YData = NaN;
    end
else
    if f.fly_markers_hidden
    else
        if ~(f.current_frame==1)
            % hide markers
            hide_these_flies = find(f.tracking_info.fly_status(:,f.previous_frame)==1);
            for flynum = 1:length(hide_these_flies)
                f.plot_handles.fly_markers(hide_these_flies(flynum)).XData = NaN;
                f.plot_handles.fly_markers(hide_these_flies(flynum)).YData = NaN;
            end
            f.fly_markers_hidden = 1;
        end
    end
end

if f.mark_lost
    f.lost_hidden = 0;
    % mark lost and gone flies anyway
    mark_these_visible = find((f.tracking_info.fly_status(:,f.current_frame))>1);
    if f.current_frame~=1
        %     hide_these_visible = setdiff(setdiff(find(~isnan(f.tracking_info.fly_status(:,f.previous_frame))),find(f.tracking_info.fly_status(:,f.previous_frame)==1)),mark_these_visible);
        mark_these_visible_prev = find((f.tracking_info.fly_status(:,f.previous_frame))>1);
        hide_these_visible = intersect(mark_these_visible_prev,find(f.tracking_info.fly_status(:,f.current_frame)==1));
    else
        hide_these_visible = [];
    end
    for flynum = 1:length(mark_these_visible)
        if getLostTime(f,mark_these_visible(flynum))>=f.max_lost_time
            hide_these_visible = [hide_these_visible;mark_these_visible(flynum)];
        else
            
            % show lost flies anyway
            if f.tracking_info.fly_status(mark_these_visible(flynum),f.current_frame) == 2
                f.plot_handles.fly_markers(mark_these_visible(flynum)).Marker = 'x';
                %         elseif f.tracking_info.fly_status(mark_these_visible(flynum),f.current_frame) == 0
                %             f.plot_handles.fly_markers(mark_these_visible(flynum)).Marker = '+';
            elseif f.tracking_info.fly_status(mark_these_visible(flynum),f.current_frame) == 3
                f.plot_handles.fly_markers(mark_these_visible(flynum)).Marker = 'd';
            elseif f.tracking_info.fly_status(mark_these_visible(flynum),f.current_frame) == 4
                f.plot_handles.fly_markers(mark_these_visible(flynum)).Marker = 'p';
            end
            f.plot_handles.fly_markers(mark_these_visible(flynum)).XData = f.tracking_info.x(mark_these_visible(flynum),f.current_frame);
            f.plot_handles.fly_markers(mark_these_visible(flynum)).YData = f.tracking_info.y(mark_these_visible(flynum),f.current_frame);
        end
    end
    for flynum = 1:length(hide_these_visible)
        f.plot_handles.fly_markers(hide_these_visible(flynum)).XData = NaN;
        f.plot_handles.fly_markers(hide_these_visible(flynum)).YData = NaN;
    end
else
    if f.lost_hidden
    else
        if ~(f.current_frame==1)
            % hide markers
            hide_these_flies = find(f.tracking_info.fly_status(:,f.previous_frame)>1);
            for flynum = 1:length(hide_these_flies)
                f.plot_handles.fly_markers(hide_these_flies(flynum)).XData = NaN;
                f.plot_handles.fly_markers(hide_these_flies(flynum)).YData = NaN;
            end
            f.lost_hidden = 1;
        end
    end
end

% always show positions
show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
hide_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)~=1);
% if f.current_frame~=1
%     hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
% else
%     hide_these_flies = [];
% end
for flynum = 1:length(show_these_flies)
    f.plot_handles.fly_positions(show_these_flies(flynum)).XData = f.tracking_info.x(show_these_flies(flynum),f.current_frame);
    f.plot_handles.fly_positions(show_these_flies(flynum)).YData = f.tracking_info.y(show_these_flies(flynum),f.current_frame);
end
for flynum = 1:length(hide_these_flies)
    f.plot_handles.fly_positions(hide_these_flies(flynum)).XData = NaN;
    f.plot_handles.fly_positions(hide_these_flies(flynum)).YData = NaN;
end

% show trajectories
if f.show_trajectories
    f.tracks_hidden = 0;
    % first delete all tracks
    try
        [f.plot_handles.fly_trajectories(:).XData] = deal(nan);
        [f.plot_handles.fly_trajectories(:).YData] = deal(nan);
    catch
    end
    show_these_flies = find((f.tracking_info.fly_status(:,f.current_frame))==1);
    for flynum = 1:length(show_these_flies)
        tempx = f.tracking_info.x(show_these_flies(flynum),1:f.current_frame);
        tempy = f.tracking_info.y(show_these_flies(flynum),1:f.current_frame);
        if f.current_frame > f.trajectory_vis_length
            tempx(1:f.current_frame-f.trajectory_vis_length) = NaN;
            tempy(1:f.current_frame-f.trajectory_vis_length) = NaN;
        end
        f.plot_handles.fly_trajectories(show_these_flies(flynum)).XData = tempx;
        f.plot_handles.fly_trajectories(show_these_flies(flynum)).YData = tempy;
    end
    %     % always hide the lost tracks
    %     hide_these_flies = find((f.tracking_info.fly_status(:,f.current_frame))>1);
    %     for flynum = 1:length(hide_these_flies)
    %         f.plot_handles.fly_trajectories(hide_these_flies(flynum)).XData = NaN;
    %         f.plot_handles.fly_trajectories(hide_these_flies(flynum)).YData = NaN;
    %     end
    %     hide_these_flies = find((f.tracking_info.fly_status(:,f.current_frame))==0);
    %     for flynum = 1:length(hide_these_flies)
    %         f.plot_handles.fly_trajectories(hide_these_flies(flynum)).XData = NaN;
    %         f.plot_handles.fly_trajectories(hide_these_flies(flynum)).YData = NaN;
    %     end
    
else
    if f.tracks_hidden
    else
        % hide markers
        hide_these_flies = find((f.tracking_info.fly_status(:,f.current_frame))>0);
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.fly_trajectories(hide_these_flies(flynum)).XData = NaN;
            f.plot_handles.fly_trajectories(hide_these_flies(flynum)).YData = NaN;
        end
        f.tracks_hidden = 1;
    end
end



% label flies
if f.label_flies
    f.labels_hidden = 0;
    show_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    hide_these_flies = find(f.tracking_info.fly_status(:,f.current_frame)~=1);
    %     if f.current_frame~=1
    %         hide_these_flies = setdiff(find(f.tracking_info.fly_status(:,f.previous_frame)==1),show_these_flies);
    %     else
    %         hide_these_flies = [];
    %     end
    for flynum = 1:length(show_these_flies)
        f.plot_handles.labels(show_these_flies(flynum)).Position = [f.tracking_info.x(show_these_flies(flynum),f.current_frame)+10,...
            f.tracking_info.y(show_these_flies(flynum),f.current_frame)-10];
    end
    for flynum = 1:length(hide_these_flies)
        f.plot_handles.labels(hide_these_flies(flynum)).Position = [NaN,NaN];
    end
else
    if f.labels_hidden
    else
        % hide markers
        hide_these_flies = find(f.tracking_info.fly_status(:,f.previous_frame)>0);
        for flynum = 1:length(hide_these_flies)
            f.plot_handles.labels(hide_these_flies(flynum)).Position = [NaN,NaN];
        end
        f.labels_hidden = 1;
        %         if ~(f.current_frame==1)
        %             % hide markers
        %             hide_these_flies = find(f.tracking_info.fly_status(:,f.previous_frame)==1);
        %             for flynum = 1:length(hide_these_flies)
        %                 f.plot_handles.labels(hide_these_flies(flynum)).Position = [NaN,NaN];
        %             end
        %             f.labels_hidden = 1;
        %         end
    end
end
