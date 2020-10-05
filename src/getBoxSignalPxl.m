function boxsignal = getBoxSignalPxl(f,flynum)
%getBoxSignalPxl returns the pixels profiles of lines in the box centered on
%the fly. the box size is defined in property: signalBoxSize
%

xc = f.tracking_info.x(flynum,f.current_frame);
yc = f.tracking_info.y(flynum,f.current_frame);
ang = -f.tracking_info.orientation(flynum,f.current_frame);
len = f.signalBoxSize(1)/f.ExpParam.mm_per_px;
height = f.signalBoxSize(2)/f.ExpParam.mm_per_px;
boxsignal = zeros(f.signalBoxSegmentNum,1);
XYC = getRectangleCorners(xc,yc,len,height,ang);
tl = XYC(1,:); % top left corner
tr = XYC(2,:);   % top right corner
br = XYC(3,:);   % bottom right corner
bl = XYC(4,:);   % bottom left corner
% contruct x coordinates
yedge_start = (tl(2)+bl(2))/2;
xedge_start = (tl(1)+bl(1))/2;

yedge_end = (tr(2)+br(2))/2;
xedge_end = (tr(1)+br(1))/2;

yedges = linspace(yedge_start,yedge_end,f.signalBoxSegmentNum+1);
xedges = linspace(xedge_start,xedge_end,f.signalBoxSegmentNum+1);

for i = 1:f.signalBoxSegmentNum
    XY = getRectanglePxls(xedges(i),yedges(i),len/f.signalBoxSegmentNum,height,ang);
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
    boxsignal(i) = mean(double((f.current_raw_frame(idx))));
end