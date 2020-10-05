function [RefMatC,label] = collectRef(f)
minObjSize = 100;
thresh = 0.5;
RefMatC = [];
label = [];
for frmnum = 1:f.nframes
    I = (f.path_name.frames(:,:,frmnum)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask);
    im = imbinarize(uint8(I),thresh);
    im = bwareaopen(im, minObjSize);
    S = regionprops(im,'Centroid', 'Orientation', 'MajorAxisLength', 'MinorAxisLength','PixelList','Area');
    % get and measure reflections
    S = PredRefGeom(S,f.ExpParam); % get reflections
    labelt = str2num(num2str((1:numel(S))'+100*frmnum));
    label = [label;labelt];
    RefMat = cutNRotRefIm(I,S);
    RefMatC = [RefMatC;RefMat];
end
    