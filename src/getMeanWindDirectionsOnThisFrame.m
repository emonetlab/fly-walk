function f = getMeanWindDirectionsOnThisFrame(f,thisFrame,interpMethod)
%getMeanWindDirectionsOnThisFrame
% f = getMeanWindDirectionsOnThisFrame(f,thisFrame)
% Interpolates the wind directios in each pixel of the virtual antenna using
% the wind direction matrix WindDirThisFrame calculated for this frame and 
% returns the mean wind direction as the orientation of the sum of the al
% direction vectors.
%

switch nargin
    case 2
        interpMethod = 'linear';
    case 1
        interpMethod = 'linear';
        thisFrame = f.current_frame;
end

% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,thisFrame)==1);
if isempty(current_flies)
    return
end

if strcmp(f.antenna_type,'fixed')
    % go over these flies and measure the signal
    for flynum = 1:length(current_flies)
        this_fly = current_flies(flynum);
        xymat_antenna = getAntPxlList(f,this_fly,'fixed',thisFrame);
        
        if isempty(xymat_antenna)
            continue
        end
        
        XwindSpdAnt = interp2(f.tracking_info.PIV.x,f.tracking_info.PIV.y,f.tracking_info.PIV.uMatrix_filt(:,:,thisFrame),xymat_antenna(:,1),xymat_antenna(:,2),interpMethod,0);
        YwindSpdAnt = interp2(f.tracking_info.PIV.x,f.tracking_info.PIV.y,f.tracking_info.PIV.vMatrix_filt(:,:,thisFrame),xymat_antenna(:,1),xymat_antenna(:,2),interpMethod,0);
        [theta,rho] = cart2pol(XwindSpdAnt,YwindSpdAnt);
        thetatemp = theta;
        thetatemp(isnan(theta)) = []; % remove nan values
        f.tracking_info.meanWindDir(this_fly,thisFrame) = meanOrientation(thetatemp/pi*180);
        f.tracking_info.meanWindSpeed(this_fly,thisFrame) = nanmean(rho);
    end
        
    
    
elseif strcmp(f.antenna_type,'dynamic')
       
          % go over these flies and measure the signal
    for flynum = 1:length(current_flies)
        this_fly = current_flies(flynum);
        xymat_antenna = getAntPxlList(f,this_fly,'dynamic',thisFrame);
        
        if isempty(xymat_antenna)
            continue
        end
        
        XwindSpdAnt = interp2(f.tracking_info.PIV.x,f.tracking_info.PIV.x,f.tracking_info.PIV.uMatrix_filt(:,:,thisFrame),xymat_antenna(:,1),xymat_antenna(:,2),'linear',0);
        YwindSpdAnt = interp2(f.tracking_info.PIV.x,f.tracking_info.PIV.x,f.tracking_info.PIV.vMatrix_filt(:,:,thisFrame),xymat_antenna(:,1),xymat_antenna(:,2),'linear',0);
        [theta,rho] = cart2pol(XwindSpdAnt,YwindSpdAnt);
        f.tracking_info.meanWindDir(this_fly,thisFrame) = meanOrientation(theta/pi*180);
        f.tracking_info.meanWindSpeed(this_fly,thisFrame) = nanmean(rho);
    end
    
end



