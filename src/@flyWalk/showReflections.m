function showReflections(f)
%showReflections
%
% showReflections(f) shows the putative reflections as black dashed ellipses


if ~f.show_reflections
    return
end
if isempty(f.tracking_info.fly_status)
    return
end 
% find previous assigned flies and reset the plots
prev_assigned_flies = find(f.tracking_info.fly_status(:,f.previous_frame)==1);
for i = 1:length(prev_assigned_flies)
    f.plot_handles.reflections(prev_assigned_flies(i)).XData = NaN;
    f.plot_handles.reflections(prev_assigned_flies(i)).YData = NaN;
end



if f.current_frame==1
    return
end

if isempty(f.current_objects)
    current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    if isempty(current_flies)
        return
    else
        S = TrackInfo2Struct(f);
    end
else
    current_flies = f.current_object_status;
    S = f.current_objects;
end
if f.show_reflections==1
    if ~isfield(S,'RX')
        S = PredRefGeom(S,f.ExpParam); % get reflections
    end
    for  fly_ind = 1:numel(S)
        phi = linspace(0,2*pi,50);
        cosphi=cos(phi);
        sinphi=sin(phi);
        xb = S(fly_ind).RX(1);
        yb = S(fly_ind).RX(2);
        a  = S(fly_ind).RMaj/2;
        b  = S(fly_ind).RMin/2;
        theta=pi*S(fly_ind).Orientation/180;
        R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
        xy = [a*cosphi; b*sinphi];
        xy = R*xy;
        x  = xy(1,:)+xb;
        y  = xy(2,:)+yb;
        f.plot_handles.reflections(current_flies(fly_ind)).XData = x;
        f.plot_handles.reflections(current_flies(fly_ind)).YData = y;
    end
    
elseif f.show_reflections==2
    
    S = PredRefGeom2(S,f.ExpParam,f.refl_dist_param(2),f.R2Resize); % get reflections
    for  fly_ind = 1:numel(S)
        phi = linspace(0,2*pi,50);
        cosphi=cos(phi);
        sinphi=sin(phi);
        xb = S(fly_ind).RX(1);
        yb = S(fly_ind).RX(2);
        a  = S(fly_ind).RMaj/2;
        b  = S(fly_ind).RMin/2;
        theta=pi*S(fly_ind).Orientation/180;
        R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
        xy = [a*cosphi; b*sinphi];
        xy = R*xy;
        x  = xy(1,:)+xb;
        y  = xy(2,:)+yb;
        f.plot_handles.reflections(current_flies(fly_ind)).XData = x;
        f.plot_handles.reflections(current_flies(fly_ind)).YData = y;
    end
    
elseif f.show_reflections==3
    if ~isfield(S,'RX')
        S = PredRefGeom(S,f.ExpParam); % get reflections
    end
    S2 = PredRefGeom2(S,f.ExpParam,f.refl_dist_param(2),f.R2Resize); % get reflections
    for  fly_ind = 1:numel(S)
        if current_flies(fly_ind) == 0
            % this is not an assigned fly, skip
            continue
        end
        phi = linspace(0,2*pi,50);
        cosphi=cos(phi);
        sinphi=sin(phi);
        xb = S(fly_ind).RX(1);
        yb = S(fly_ind).RX(2);
        a  = S(fly_ind).RMaj/2;
        b  = S(fly_ind).RMin/2;
        theta=pi*S(fly_ind).Orientation/180;
        R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
        xy = [a*cosphi; b*sinphi];
        xy = R*xy;
        x  = xy(1,:)+xb;
        y  = xy(2,:)+yb;
        
        xb = S2(fly_ind).RX(1);
        yb = S2(fly_ind).RX(2);
        a  = S2(fly_ind).RMaj/2;
        b  = S2(fly_ind).RMin/2;
        theta=pi*S2(fly_ind).Orientation/180;
        R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
        xy = [a*cosphi; b*sinphi];
        xy = R*xy;
        x2  = xy(1,:)+xb;
        y2  = xy(2,:)+yb;
        
        x = [x,NaN,x2];
        y = [y,NaN,y2];
        
        
        f.plot_handles.reflections(current_flies(fly_ind)).XData = x;
        f.plot_handles.reflections(current_flies(fly_ind)).YData = y;
    end
    
end