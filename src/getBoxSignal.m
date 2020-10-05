function boxsignal = getBoxSignal(f,flynum)
%getBoxSignal returns the pixels profiles of lines in the box centered on
%the fly. the box size is defined in property: signalBoxSize
%

xc = f.tracking_info.x(flynum,f.current_frame);
yc = f.tracking_info.y(flynum,f.current_frame);
ang = -f.tracking_info.orientation(flynum,f.current_frame);
len = f.signalBoxSize(1)/f.ExpParam.mm_per_px;
height = f.signalBoxSize(2)/f.ExpParam.mm_per_px;
boxsignal = zeros(ceil(len/f.signalBoxSegmentNum)*f.signalBoxSegmentNum+1,round(height));
XY = getRectangleCorners(xc,yc,len,height,ang);
tl = XY(1,:); % top left corner
tr = XY(2,:);   % top right corner
br = XY(3,:);   % bottom right corner
bl = XY(4,:);   % bottom left corner
% contruct x coordinates
xvec_start = linspace(tl(1),bl(1),round(height));
yvec_start = linspace(tl(2),bl(2),round(height));

xvec_end = linspace(tr(1),br(1),round(height));
yvec_end = linspace(tr(2),br(2),round(height));

for i = 1:round(height)
    [~,~,c] = improfile(f.current_raw_frame,[xvec_start(i),xvec_end(i)],[yvec_start(i),yvec_end(i)],ceil(len/f.signalBoxSegmentNum)*f.signalBoxSegmentNum+1);
    boxsignal(:,i) = c;
end