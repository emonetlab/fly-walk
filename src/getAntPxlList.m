function antpxls = getAntPxlList(f,this_fly,fixedOrdynamic,frameNum)
% generates the indexes for the antenna location fo the given fly
switch nargin
    case 3
        frameNum = f.current_frame;
    case 2
        frameNum = f.current_frame;
        fixedOrdynamic = 'fixed';
end

% generates antenna pixel list
xc= f.tracking_info.x(this_fly,frameNum);
yc= f.tracking_info.y(this_fly,frameNum);
Theta =  f.tracking_info.orientation(this_fly,frameNum)/180*pi;
if isnan(Theta)
 antpxls = [];
 return
end
if strcmp(fixedOrdynamic,'fixed')
    antoffset = f.antoffset(this_fly); % retuns the natenna whose distance to fly center is fixed
elseif strcmp(fixedOrdynamic,'dynamic') % return the antenna optimized for each frame
    antoffset = f.tracking_info.antoffsetAF(this_fly,frameNum);
end
%%%%%%% ANTENNA PARAMETERS
%generate coordinates for antenna
ant_maj = f.tracking_info.minax(this_fly,frameNum)/f.antlen;
ant_min = f.tracking_info.minax(this_fly,frameNum)/f.antwd;
ant_ornt = Theta + pi/2;
x_ant = xc + f.tracking_info.majax(this_fly,frameNum).*antoffset.*cos(Theta);
y_ant = yc + f.tracking_info.majax(this_fly,frameNum).*antoffset.*sin(Theta);
if isnan(ant_min)
    antpxls = [];
    f.tracking_info.error_code(this_fly,frameNum) = 6;
    return
end

if strcmp(f.antenna_shape,'box')
    ang = -f.tracking_info.orientation(this_fly,frameNum)+90;
    antpxls = getBoxAntennaPixels(f,this_fly,x_ant,y_ant,ang);
else
    % generate the pixel list for antenna location
    antpxls = getShapePixels(f,ant_min,ant_maj,ant_ornt,x_ant,y_ant);
    % antpxls = ellips_mat_aneq(ant_min,ant_maj,ant_ornt,x_ant,y_ant);
end

% clean the bad pixels
[imyl,imxl]=size(f.current_raw_frame); % image limits
if ~isempty(antpxls)
    antpxls(antpxls(:,2)<1,:)=[];
    antpxls(antpxls(:,1)<1,:)=[];
    antpxls(antpxls(:,2)>imyl,:)=[];
    antpxls(antpxls(:,1)>imxl,:)=[];
end
