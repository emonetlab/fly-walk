function f = showAntenna(f)
%showAntenna
% creates virtual antenna and plots them

if ~f.show_antenna
    if f.antenna_hidden
    else
        % which flies are currently assigned
        all_flies = 1:length(f.tracking_info.fly_status(:,f.previous_frame));
        
        for flynum = 1:length(all_flies)
            f.plot_handles.fly_antenna(all_flies(flynum)).XData = NaN;
            f.plot_handles.fly_antenna(all_flies(flynum)).YData = NaN;
            f.plot_handles.fly_antenna_seg(all_flies(flynum)).XData = NaN;
            f.plot_handles.fly_antenna_seg(all_flies(flynum)).YData = NaN;
        end
        f.antenna_hidden = 1;
        %         if f.current_frame~=1
        %             % which flies are currently assigned
        %             prev_assigned_flies = 1:length(f.tracking_info.fly_status(:,f.previous_frame));
        %
        %             for flynum = 1:length(prev_assigned_flies)
        %                 f.plot_handles.fly_antenna(prev_assigned_flies(flynum)).XData = NaN;
        %                 f.plot_handles.fly_antenna(prev_assigned_flies(flynum)).YData = NaN;
        %             end
        %             f.antenna_hidden = 1;
        %         end
    end
else
    f.antenna_hidden = 0;
    % which flies are currently assigned
    current_assigned_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    
    % which of these are interacting
    current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
        find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];
    
    % remove interacting flies
    current_assigned_flies(logical(sum(current_assigned_flies==current_interacting_flies',2))) = [];
    
    %     if f.current_frame~=1
    %         prev_assigned_flies = find(f.tracking_info.fly_status(:,f.previous_frame)==1);
    %
    %         % which of these are interacting
    %         prev_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.previous_frame)));...
    %             find(~isnan(f.tracking_info.overpassing(:,f.previous_frame)))];
    %
    %         % remove interacting flies
    %         prev_assigned_flies(logical(sum(prev_assigned_flies==prev_interacting_flies',2))) = [];
    %     else
    %         prev_assigned_flies = [];
    %     end
    
    show_these_antenna = current_assigned_flies;
    all_flies = 1:length(f.tracking_info.fly_status(:,f.current_frame));
    hide_these_antenna = setdiff(all_flies,current_assigned_flies);
    
    % go over these flies and update antenna plot
    for flynum = 1:length(show_these_antenna)
        
        if strcmp(f.antenna_type,'fixed')||(~isfield(f.tracking_info,'antoffsetAF'))
            xymat_antenna = getAntPxlList(f,show_these_antenna(flynum),'fixed');
        elseif strcmp(f.antenna_type,'dynamic')
            xymat_antenna = getAntPxlList(f,show_these_antenna(flynum),'dynamic');
        elseif strcmp(f.antenna_type,'fixed')
            xymat_antenna = getAntPxlList(f,show_these_antenna(flynum),'fixed');
        else
            keyboard
        end
        
        if ~isempty(xymat_antenna)
            if strcmp(f.antenna_shape,'box')
                % color odd and even segments differently
                evenSegments = logical(mod(xymat_antenna(:,3),2)==0);
                oddSegments = logical(mod(xymat_antenna(:,3),2)~=0);
%                 evenSegments = logical(xymat_antenna(:,3)==1); % use to visualize which end is the first one. 1. segment is the one on the far right
%                 oddSegments = logical(xymat_antenna(:,3)~=1);
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).XData = xymat_antenna(evenSegments,1);
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).YData = xymat_antenna(evenSegments,2);
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).XData = xymat_antenna(oddSegments,1);
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).YData = xymat_antenna(oddSegments,2);
            else
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).XData = xymat_antenna(:,1);
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).YData = xymat_antenna(:,2);
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).XData = nan;
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).YData = nan;
            end
        else
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).XData = NaN;
                f.plot_handles.fly_antenna(show_these_antenna(flynum)).YData = NaN;
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).XData = NaN;
                f.plot_handles.fly_antenna_seg(show_these_antenna(flynum)).YData = NaN;
        end
        
    end
    
    % remove others
    for flynum = 1:length(hide_these_antenna)
            f.plot_handles.fly_antenna(hide_these_antenna(flynum)).XData = NaN;
            f.plot_handles.fly_antenna(hide_these_antenna(flynum)).YData = NaN;
            f.plot_handles.fly_antenna_seg(hide_these_antenna(flynum)).XData = NaN;
            f.plot_handles.fly_antenna_seg(hide_these_antenna(flynum)).YData = NaN;
    end
end

