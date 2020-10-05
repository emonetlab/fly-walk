function numFly = CountFlies(f)

numFly = zeros(f.nframes,1);

for i = 1:f.nframes
    image = (f.path_name.frames(:,:,i)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask);
    
    image(image<f.fly_body_threshold) = 0;
    L = logical(image);
    r = regionprops(L);

    % remove very small objects as they might be noise
    r([r.Area]<f.min_fly_area) = [];
    numFly(i) = numel(r);
end