function ImIsolated = IsolateFly(f,thisfly,margin_pxl)

switch nargin
    case 2
        margin_pxl = 0; %  just use the boundign box
end
% subtract background, apply mask
imt = (f.current_raw_frame-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask);

% get the bounding box of the fly
bbox = round(f.current_objects(thisfly).BoundingBox);

% initiate the empty image and register the fly of the interest
ImIsolated = zeros(size(imt));
ImIsolated(bbox(2)-margin_pxl:bbox(2)+bbox(4)+margin_pxl,bbox(1)-margin_pxl:bbox(1)+bbox(3)+margin_pxl) =...
    imt(bbox(2)-margin_pxl:bbox(2)+bbox(4)+margin_pxl,bbox(1)-margin_pxl:bbox(1)+bbox(3)+margin_pxl); 
