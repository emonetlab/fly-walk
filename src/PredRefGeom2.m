function ref = PredRefGeom2(fly,p,confac,R2Resize)
%PredRefGeom
%   PredRefGeom(fly) generates ref parameters using the geometrical
%   approximation
% fly: 1d vector with parameters: x,y,a,b,theta,camx,camy;
% using the geometrical model generates location (x,y). minor and major axis
% (a,b) and orientation of the fly relative to the camera. or a structure
% with the fields:  
% Centroid, MajorAxis, MinorAxis,and Orientation
% p is the parameter structure which should contain camera properties



% if structure is given, do this
if isstruct(fly)
    if nargin==1
        p = [];
        disp('provide p')
    end
    
    for flynum = 1:(numel(fly))
        % get cordinates
        xrel = fly(flynum).Centroid(1)-p.camera.x;
        yrel = fly(flynum).Centroid(2)-p.camera.y;
        rho = sqrt(xrel^2+yrel^2)*confac; % the distance of ref relative to the camera
        theta = cart2pol(xrel,yrel);  % direction from camera to fly center
        [xref1,xref2] = pol2cart(theta,rho);  % get ref postions relative to camera
        fly(flynum).RX(1) = xref1 + p.camera.x;     % add cam offset
        fly(flynum).RX(2) = xref2 + p.camera.y;     % add cam offset

        % major and minor axis
        fly(flynum).RMaj = confac.*fly(flynum).MajorAxisLength.*R2Resize;
        fly(flynum).RMin = confac.*fly(flynum).MinorAxisLength.*R2Resize;

        % orientation
        fly(flynum).ROr = mod(fly(flynum).Orientation,360);
        
        
    end
    
    ref = fly;
else
    
ref = zeros(size(fly,1),5);



% get cordinates 
rho = sqrt((fly(:,1)-fly(:,6)).^2+(fly(:,2)-fly(:,7)).^2)*confac; % distance between reflection and the camera
theta = cart2pol(fly(:,1)-fly(:,6),fly(:,2)-fly(:,7));  % direction from camera to fly
[ref(:,1),ref(:,2)] = pol2cart(theta,rho);  % get ref postions relative to fly
ref(:,1) = ref(:,1) + fly(:,6);     % add camera offset
ref(:,2) = ref(:,2) + fly(:,7);     % add camera offset

% major and minor axis
ref(:,3) = confac.*fly(:,3);
ref(:,4) = confac.*fly(:,4);

% orientation
ref(:,5) = confac.*mod(fly(:,5),360);
end