function xymat_antenna = getBoxAntennaPixels(f,flynum,x_ant,y_ant,ant_ornt)
%getBoxAntennaPixels: return the pixel lists, segment index and linear
%matrix indexes on a virtual antena of rectangular shape.
%   xymat_antenna = getBoxAntennaPixels(f,flynum,x_ant,y_ant,ant_ornt)
%   The width of the virtual antenna is set to 3 pixels, and length of the
%   antenna is the mean width of the fly istelf
%

xymat_antenna = []; % initiate the empty output. xpxl, ypxl, segment index, linear index
len = round(1.2*nanmean(f.tracking_info.minax(flynum,:)));
if ~(mod(len,2)==0)    % odd, make it even, increase by one
    len = len + 1;
end
    
height = 2; % pxls, make it parameteric if necessary
XYC = getRectangleCorners(x_ant,y_ant,len,height,ant_ornt);
tl = XYC(1,:);   % top left corner
tr = XYC(2,:);   % top right corner
br = XYC(3,:);   % bottom right corner
bl = XYC(4,:);   % bottom left corner

% contruct x coordinates
yedge_start = (tl(2)+bl(2))/2;
xedge_start = (tl(1)+bl(1))/2;

yedge_end = (tr(2)+br(2))/2;
xedge_end = (tr(1)+br(1))/2;

yedges = linspace(yedge_start,yedge_end,len+1);
xedges = linspace(xedge_start,xedge_end,len+1);

for i = 1:len
    XY = getRectanglePxls(xedges(i),yedges(i),1,height,ant_ornt);
    XY(XY(:,1)<1,:) = [];
    XY(XY(:,2)<1,:) = [];
    XY(XY(:,1)>size(f.current_raw_frame,2),:) = [];
    XY(XY(:,2)>size(f.current_raw_frame,1),:) = [];
    idx = sub2ind(size(f.current_raw_frame),XY(:,2),XY(:,1));
    idx(idx<1) = [];
    idx(isnan(idx)) = [];
    if isempty(idx)
        continue
    end
    xymattemp = [XY,ones(size(idx))*i,idx];
    if ~isempty(xymat_antenna)
        xymattemp(logical(sum(xymattemp(:,4)==xymat_antenna(:,4)',2)),:) = [];
        xymat_antenna = [xymat_antenna;xymattemp];
    else
        xymat_antenna = [xymat_antenna;xymattemp];
    end
    
end