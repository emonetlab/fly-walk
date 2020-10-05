function f = showWindSpeed(f)
%showWindDir
% shows the average wind direction on the fly antenna as an arrow at the
% fly center
%

if ~f.show_windSpeed
    if strcmp(f.windSpeedStatus,'off')
        return
    else
        % supress the flow field
        for i = 1:numel(f.plot_handles.windSpeed)
            f.plot_handles.windSpeed(i).Position = [NaN,NaN];
            f.windSpeedStatus = 'off';
        end
    end
else
    if ~isfield(f.tracking_info,'PIV')
        return
    end
    f.windSpeedStatus = 'on';
    
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
    
    show_these_windSpeed = current_assigned_flies;
    hide_these_windSpeed = setdiff(prev_assigned_flies,current_assigned_flies);
    
    % go over these flies and update the plotting information
    for flyNum = 1:length(show_these_windSpeed)
        
        thisFly = show_these_windSpeed(flyNum);
        thisWindSpeed = f.tracking_info.meanWindSpeed(thisFly,f.current_frame)*f.ExpParam.mm_per_px*f.ExpParam.fps;
       
        f.plot_handles.windSpeed(thisFly).Position = [f.tracking_info.x(show_these_windSpeed(flyNum),f.current_frame)+10,...
            f.tracking_info.y(show_these_windSpeed(flyNum),f.current_frame)+50];
        f.plot_handles.windSpeed(thisFly).String = [num2str(thisWindSpeed,'%5.2f'),' mm/s'];
       
        
    end
    
    % remove others
    for flyNum = 1:length(hide_these_windSpeed)
        thisFly = hide_these_windSpeed(flyNum);
        f.plot_handles.windSpeed(thisFly).Position = [NaN,NaN];
    end
end

