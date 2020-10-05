function [S,current_flies] = TrackInfo2Struct(f,thisFly,thisFrame)  
% return a structure of assigned flies. This function is usefull when
% tracking is inactive but the current_objects structure is needed.

switch nargin
    case 3
        current_flies = thisFly;
    case 2
        thisFrame = f.current_frame;
        current_flies = thisFly;
    case 1
        thisFrame = f.current_frame;
        current_flies = find(f.tracking_info.fly_status(:,thisFrame)==1);
end

S(length(current_flies)).Centroid = [];
S(length(current_flies)).MajorAxisLength = [];
S(length(current_flies)).MinorAxisLength = [];
S(length(current_flies)).Orientation = [];
S(length(current_flies)).FlyNum = [];

for flynum = 1:length(current_flies)
        % get cordinates
        S(flynum).Centroid(1) = f.tracking_info.x(current_flies(flynum),thisFrame);
        S(flynum).Centroid(2) = f.tracking_info.y(current_flies(flynum),thisFrame);

        % major and minor axis
        S(flynum).MajorAxisLength = f.tracking_info.majax(current_flies(flynum),thisFrame);
        S(flynum).MinorAxisLength = f.tracking_info.minax(current_flies(flynum),thisFrame);

        % orientation
        S(flynum).Orientation = -f.tracking_info.orientation(current_flies(flynum),thisFrame);
        S(flynum).FlyNum = current_flies(flynum);
end