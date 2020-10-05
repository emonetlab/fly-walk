function xymat_antenna = getShapePixels(f,ant_min,ant_maj,ant_ornt,x_ant,y_ant)
% returns the virtual antenna pixels of the
% which antenna shape is requested


if strcmp(f.antenna_shape,'ellipse')
    
elseif strcmp(f.antenna_shape,'circle')
    ant_min = ant_maj;
else
    disp('undefined antenna shape')
    keyboard
end

xymat_antenna = ellips_mat_aneq(ant_min,ant_maj,ant_ornt,x_ant,y_ant);
