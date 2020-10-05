function f = showWindDir(f)
%showWindDir
% shows the average wind direction on the fly antenna as an arrow at the
% fly center
%

if ~f.show_winddir
    if strcmp(f.windDirStatus,'off')
        return
    else
        % supress the flow field
        for i = 1:numel(f.plot_handles.windDir)
            f.plot_handles.windDir(i).XData = NaN;
            f.plot_handles.windDir(i).YData = NaN;
            f.plot_handles.windDir(i).UData = NaN;
            f.plot_handles.windDir(i).VData = NaN;
            f.windDirStatus = 'off';
        end
    end
else
    if ~isfield(f.tracking_info,'PIV')
        return
    end
    f.windDirStatus = 'on';
    
    % which flies are currently assigned
    current_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    
    % which of these are interacting
    current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
        find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];
    
    % remove interacting flies
    current_assigned_flies(logical(sum(current_assigned_flies==current_interacting_flies',2))) = [];
    
    if f.current_frame~=1
        prev_assigned_flies = find(f.tracking_info.fly_status(:,f.previous_frame)==1);
        
        % which of these are interacting
        prev_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.previous_frame)));...
            find(~isnan(f.tracking_info.overpassing(:,f.previous_frame)))];
        
        % remove interacting flies
        prev_assigned_flies(logical(sum(prev_assigned_flies==prev_interacting_flies',2))) = [];
    else
        prev_assigned_flies = [];
    end
    
    show_these_windDir = current_assigned_flies;
    hide_these_windDir = setdiff(prev_assigned_flies,current_assigned_flies);
    
    % go over these flies and update the plotting information
    for flyNum = 1:length(show_these_windDir)
        
        thisFly = show_these_windDir(flyNum);
        [ufly,vfly] = pol2cart(f.tracking_info.meanWindDir(thisFly,f.current_frame)/180*pi,f.tracking_info.meanWindSpeed(thisFly,f.current_frame));
       
        f.plot_handles.windDir(thisFly).XData = f.tracking_info.x(thisFly,f.current_frame);
        f.plot_handles.windDir(thisFly).YData = f.tracking_info.y(thisFly,f.current_frame);
        f.plot_handles.windDir(thisFly).UData = ufly;
        f.plot_handles.windDir(thisFly).VData = vfly;
        f.plot_handles.windDir(thisFly).Color = f.windDirColor;
        f.plot_handles.windDir(thisFly).AutoScaleFactor = f.windDirScaleFactor;
        f.plot_handles.windDir(thisFly).LineWidth = f.windDirLineWidth;
        
    end
    
    % remove others
    for flyNum = 1:length(hide_these_windDir)
        thisFly = hide_these_windDir(flyNum);
        f.plot_handles.windDir(thisFly).XData = NaN;
        f.plot_handles.windDir(thisFly).YData = NaN;
        f.plot_handles.windDir(thisFly).UData = NaN;
        f.plot_handles.windDir(thisFly).VData = NaN;
    end
end

