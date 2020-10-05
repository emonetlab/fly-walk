function f = getAllFlyGradOrs(f,these_flies)
% calculates the orientations of all flies in the current frame by using
% the fly intensity gradient

if nargin==1
    these_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
end

% reconstruct current objects
if isempty(f.current_objects)
    f = reConstructCurrentObjetcs(f);
end

flies_with_object = intersect(f.current_object_status,these_flies);

S = f.current_objects;

for flynum = 1:length(flies_with_object)
    orind = find(f.tracking_info.grador(flies_with_object(flynum),:)==0,1);
    Stemp = S(f.current_object_status==flies_with_object(flynum));
    theta = getFlyGradOrientation(f,Stemp);
    
    if isempty(theta)
        f.tracking_info.orientation(flies_with_object(flynum)) = mod(-Stemp.Orientation,360);
        if ~(orind > f.nFramesforGradOrient)
            f.tracking_info.grador(flies_with_object(flynum),orind) = mod(-Stemp.Orientation,360);
        end
    else
        f.tracking_info.orientation(flies_with_object(flynum)) = theta;
        if ~(orind > f.nFramesforGradOrient)
            f.tracking_info.grador(flies_with_object(flynum),orind) = theta;
        end
    end

end
