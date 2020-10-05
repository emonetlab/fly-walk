function xymat_ellipse = ellips_matrix_reflections(minor_half,major_half,ang_degree,xc,yc,method)
%   ellips_mat_aneq(minor_half,major_half,theta,xc,yc) produces ellipse coordinated matrix
%
%   xymat_ellipse = ellips_mat_aneq(minor_half,major_half,ang_degree,xc,yc)
%   contructs a matrix of x and y values of all points inside an ellipse
%   defined by minor_half and major_half axis, tilt angle relative to the 
%   x axis (degrees) and ellipsoid centered at xc and yc.
%   method: 1: horizontal ellips at origin, get pixels, rotate and move, 2:
%   find boundaries of the ellips and get all pixels. Method 1 produces
%   missing pixels

if nargin==5
    method = 2; % go check one by one
end
if (method>2)||(method<1)
    disp('Method is set to 2.')
    method = 2;
end

if method==1
    % fix orientation between 0 and 180
    ang = mod(ang_degree,180);

    % convert angle into radian
    theta = pi*ang/180;

    % form the rotation matrix
    R = [ cos(theta) sin(theta);...
         -sin(theta) cos(theta)];

    %generate pixels list at origin with horizontal ellips
     % take the fly to origin, prepare for inverse rotation
    % get x and y values on the ellipse
    phi = linspace(0,2*pi,50);
    cosphi=cos(phi);
    sinphi=sin(phi);

    xy = [major_half*cosphi; minor_half*sinphi];
    x  = xy(1,:);
    y  = xy(2,:);

    % determine the unique x indexes and y indexes and get calculation range
    lenx = length(max(ceil(x)):min(floor(x)));
    leny = length(max(ceil(y)):min(floor(y)));

    if(isnan(lenx)||isnan(leny))

    xymate = [round(xc),round(yc)];
    disp('NaN on ellipse.');

    else

    xymate = zeros(lenx*leny,2);
    cnt = 0;
    for i = min(floor(x)):max(ceil(x))
        for j = min(floor(y)):max(ceil(y))
            if ((i)^2/major_half^2+(j)^2/minor_half^2)<=1
                cnt = cnt + 1;
                xymate(cnt,:) = [i,j];
            end
        end
    end

    end

    xymat_ellipse = xymate(1:cnt,:);

    % rotate the pixel list
    xymat_ellipse = R*xymat_ellipse';
    xymat_ellipse = xymat_ellipse';
    xymat_ellipse(:,1)  = round(xymat_ellipse(:,1) + xc);
    xymat_ellipse(:,2)  = round(xymat_ellipse(:,2) + yc);
    
elseif method==2
    
        % fix orientation between 0 and 180
    ang = mod(ang_degree,180);

    % convert angle into radian
    theta = pi*ang/180;

    % form the rotation matrix
    R = [ cos(theta) sin(theta);...
         -sin(theta) cos(theta)];

    %generate pixels list of the ellips

    phi = linspace(0,2*pi,50);
    cosphi=cos(phi);
    sinphi=sin(phi);
    xy = [major_half*cosphi; minor_half*sinphi];
    xy = R*xy;
    x  = (xy(1,:)+xc);
    y  = (xy(2,:)+yc);


    % determine the unique x indexes and y indexes and get calculation range
    lenx = length(max(ceil(x)):min(floor(x)));
    leny = length(max(ceil(y)):min(floor(y)));
    
    % get x with floor and ceiling
    x = [floor(x),ceil(x)];
    y = [y,y];

    if(isnan(lenx)||isnan(leny))

        xymate = [round(xc),round(yc)];
        disp('NaN on ellipse.');

    else

        xymate = zeros(lenx*leny,2);
        cnt = 0;
        for i = min(floor(x)):max(ceil(x))
            % find all y values on the ellips with this x
            % and get how many unique ones there are
            if length(unique(y(x == i)))==1
                cnte = cnt + 1;
                xymate(cnt+1:cnte,:) = [i,round(unique(y(x == i)))];
                cnt = cnte;
            elseif length(unique(y(x == i)))>1
                ytxu = unique(y(x == i));
                ytxl = min(floor(ytxu)):max(ceil(ytxu));
                cnte = cnt + length(ytxl);
                xymate(cnt+1:cnte,:) = [ones(length(ytxl),1)*i,ytxl'];
                cnt = cnte;
            end
        end

    end

    xymat_ellipse = xymate(1:cnt,:);
else
    error('There is no method defined in this category')
end