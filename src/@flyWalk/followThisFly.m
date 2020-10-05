function f = followThisFly(f)
% sets the figure limits to the box size around the given fly

% if the status is set to nan change it to off
if isempty(f.followThisFlyNumber)
    f.followThisFlyNumber = 'off';
    f.followThisFlyNumber = nan;
end
if isnan(f.followThisFlyNumber)
    f.followThisFlyNumber = 'off';
end

if isnumeric(f.followThisFlyNumber)
    assert(isscalar(f.followThisFlyNumber),'Fly to be followed has to be a single fly')
    
    % if fly is not assigned or box is not defined return
if f.tracking_info.fly_status(f.followThisFlyNumber,f.current_frame)~=1
    return
end

% get the limits
[bymin,bymax,bxmin,bxmax] = getFlyBox(f.followBoxSize,f.current_raw_frame,[f.tracking_info.x(f.followThisFlyNumber,f.current_frame),f.tracking_info.y(f.followThisFlyNumber,f.current_frame)]);



% set the limits
if isnumeric(f.followNZoom)
    if f.followNZoomStatus==f.followNZoom
        set(f.plot_handles.ax,'xlim',[bxmin,bxmax],'ylim',[bymin bymax])
    else
        yminl = linspace(1,bymin,f.followNZoom+1);
        ymaxl = linspace(size(f.current_raw_frame,1),bymax,f.followNZoom+1);
        xminl = linspace(1,bxmin,f.followNZoom+1);
        xmaxl = linspace(size(f.current_raw_frame,2),bxmax,f.followNZoom+1);
        f.followNZoomStatus = f.followNZoomStatus + 1;
        n = f.followNZoomStatus;
        set(f.plot_handles.ax,'xlim',[xminl(n),xmaxl(n)],'ylim',[yminl(n),ymaxl(n)])
    end
else
    set(f.plot_handles.ax,'xlim',[bxmin,bxmax],'ylim',[bymin bymax])
end
    
f.followThisFlyStatus = 'on';
else
    if strcmp(f.followThisFlyStatus,'off')
        return
    else
        if f.followNZoomStatus>0
            xl = get(f.plot_handles.ax,'xlim');
            yl = get(f.plot_handles.ax,'ylim');
            yminl = linspace(1,yl(1),f.followNZoomStatus+1);
            ymaxl = linspace(size(f.current_raw_frame,1),yl(2),f.followNZoomStatus+1);
            xminl = linspace(1,xl(1),f.followNZoomStatus+1);
            xmaxl = linspace(size(f.current_raw_frame,2),xl(2),f.followNZoomStatus+1);
            f.followNZoomStatus = f.followNZoomStatus - 1;
            set(f.plot_handles.ax,'xlim',[xminl(end-1),xmaxl(end-1)],'ylim',[yminl(end-1),ymaxl(end-1)])
        else
            set(f.plot_handles.ax,'xlim',[1,size(f.current_raw_frame,2)],'ylim',[1,size(f.current_raw_frame,1)]);
            f.followThisFlyStatus = 'off';
        end
    end
end