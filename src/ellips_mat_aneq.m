function xymat_ellipse = ellips_mat_aneq(minor,major,ang,xc,yc)
%   ellips_mat_aneq(minor,major,ang,xc,yc) produces ellipse coordinated matrix
%
%   xymat_ellipse = ellips_mat_aneq(minor,major,ang,xc,yc)
%   contructs a matrix of x and y values of all points inside an ellipse
%   defined by minor and major axis, tilt angle relative to the x axis and
%   ellipsoid centered at xc and yc.
    
[x,y]=ellipse_xy_gen(minor,major,ang,xc,yc);    % get x and y values on the ellipse
xint = round(x);
yint = round(y);

lenx = max(xint)-min(xint)+1;
leny = max(yint)-min(yint)+1;
xymat = NaN(lenx,leny,2); % x,y

for i = min(xint):max(xint)
    for j = min(yint):max(yint)
        if (((i-xc)*cos(ang)+(j-yc)*sin(ang))^2/major^2+((i-xc)*sin(ang)-(j-yc)*cos(ang))^2/minor^2)<=1
            xymat(i-min(xint)+1,j-min(yint)+1,1) = i;
            xymat(i-min(xint)+1,j-min(yint)+1,2) = j;
        end
    end
end
xlist = (squeeze(xymat(:,:,1)));
xlist = xlist(:);
ylist = (squeeze(xymat(:,:,2)));
ylist = ylist(:);
xymat_ellipse = [xlist,ylist];
xymat_ellipse(isnan(xymat_ellipse(:,1)),:) = [];