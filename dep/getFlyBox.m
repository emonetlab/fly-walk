function [bymin,bymax,bxmin,bxmax]=getFlyBox(BoxSize,I,XY)
% return the boundaries of a cropped fly box in the given frame

[y_bo,x_bo]=size(I);    % get boundary indices
% if symmetric box requested
if isscalar(BoxSize)
    lewx = round(BoxSize/2); %length to each way pxl
    lewy = round(BoxSize/2); %length to each way pxl
else %
    assert(length(BoxSize)==2,'Box size has to be a vector of two elements: [BoxsizeX,BoxsizeY]')
    lewx = round(BoxSize(1)/2); %length to each way pxl
    lewy = round(BoxSize(2)/2); %length to each way pxl
end
Xc = XY(1);
Yc = XY(2);
bymin = round(Yc-lewy);
bymax = round(Yc+lewy);
bxmin = round(Xc-lewx);
bxmax = round(Xc+lewx);

% check if the box goes out of the boundary and correect that
if bymax-bymin+1 < BoxSize
    while bymax-bymin+1 < BoxSize
        bymax = bymax + 1;
    end
elseif bymax-bymin+1 > BoxSize
    while bymax-bymin+1 > BoxSize
        bymax = bymax - 1;
    end
end

if bxmax-bxmin+1 < BoxSize
    while bxmax-bxmin+1 < BoxSize
        bxmax = bxmax + 1;
    end
elseif bxmax-bxmin+1 > BoxSize
    while bxmax-bxmin+1 > BoxSize
        bxmax = bxmax - 1;
    end
end


if bymin<=0
    bymin = 1;
end
if bymax>y_bo
    bymax = y_bo;
end
if bxmin<=0
    bxmin = 1;
end
if bxmax>x_bo
    bxmax = x_bo;
end