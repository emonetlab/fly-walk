function BTh = ThreshImages4PIV(A,B,parameters)

SmokeThreshold = parameters.SmokeThreshold;
camera = parameters.camera;
%apply median filter, can be made programmable
median_filterA = parameters.median_filterA;
median_filterB = parameters.median_filterB;
medfiltsize = parameters.medfiltsize;
if median_filterA
    A = medfilt2(A,ones(2,1)*medfiltsize);
end
if median_filterB
    B = medfilt2(B,ones(2,1)*medfiltsize);
end

BTh = B;
% get fly mask for piv calculation
% dilation and mask parameters
diln = parameters.diln;
thresh = parameters.thresh;
minObjSize = parameters.minObjSize;
[MaskPIV,~] = getFlyNRefMask((A+B)/2,camera,diln,thresh,minObjSize);
BTh(MaskPIV) = 0;         % If needed, generate via: imagesc(image); [temp,Mask{1,1},Mask{1,2}]=roipoly;
BTh(BTh<SmokeThreshold) = 0;





