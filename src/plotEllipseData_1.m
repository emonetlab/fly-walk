function plotEllipseData_1(S,I) 
    clf;
    hold on;
    imagesc(I);
    phi = linspace(0,2*pi,50);
    cosphi=cos(phi);
    sinphi=sin(phi);
    for k=1:numel(S)
        xb = S(k).Centroid(1);
        yb = S(k).Centroid(2);
        a  = S(k).MajorAxisLength/2;
        b  = S(k).MinorAxisLength/2;
        theta=pi*S(k).Orientation/180;
        R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
        xy = [a*cosphi; b*sinphi];
        xy = R*xy;
        x  = xy(1,:)+xb;
        y  = xy(2,:)+yb;
        plot(x,y,'r-','LineWidth',2);
    end
end