function pxls = PredRefGeomFly(f,this_fly,refOrder,resize_ref,frameNum)
%PredRefGeomFly
%   PredRefGeomFly(f,this_fly,refOrder) generates reflection pixles for the
% given fly: this_fly in flywalk object: f. refOrder defines the reflection
% type. 1: fly walking on top surface and reflection is on the bottom surface.
% 2: fly is on the bottom surface and reflection is on the bottom of the bottom surface
switch nargin
    case 4
        frameNum = f.current_frame;
    case 3
        frameNum = f.current_frame;
        resize_ref = 1; %do not change the reflection size
    case 2
        frameNum = f.current_frame;
        resize_ref = 1; %do not change the reflection size
        refOrder = 1;
end


% experimetally obtained conversion factor
confac = f.refl_dist_param(refOrder);

xrel = f.tracking_info.x(this_fly,frameNum)-f.ExpParam.camera.x;
yrel = f.tracking_info.y(this_fly,frameNum)-f.ExpParam.camera.y;
rho = sqrt(xrel^2+yrel^2)*confac; % the distance of ref relative to the camera
theta = cart2pol(xrel,yrel);  % direction from camera to fly center
[xref1,xref2] = pol2cart(theta,rho);  % get ref postions relative to camera
RX(1) = xref1 + f.ExpParam.camera.x;     % add cam offset
RX(2) = xref2 + f.ExpParam.camera.y;     % add cam offset

% major and minor axis
RMaj = confac.*f.tracking_info.majax(this_fly,frameNum).*resize_ref;
RMin = confac.*f.tracking_info.minax(this_fly,frameNum).*resize_ref;

% orientation
ROr = mod(f.tracking_info.orientation(this_fly,frameNum),360);

pxls = ellips_matrix_reflections(RMin/2,RMaj/2,-ROr,RX(1),RX(2));
        
