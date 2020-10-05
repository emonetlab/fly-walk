function [x,y,u,v,typevector,A,B] = pivImages(A,B,parameters)

camera = parameters.camera;
s = parameters.s;  % PIV settings
p = parameters.p;  % Image pre-process settings
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

% flies masks can be set to zero, disabled for now
setFliestoZero = parameters.setFliestoZero;

% get fly mask for piv calculation
% dilation and mask parameters
diln = parameters.diln;
thresh = parameters.thresh;
minObjSize = parameters.minObjSize;
if parameters.UseMask         % apply mask to images
    if strcmp(parameters.MaskType,'binary') % binary: use binary mask, else use cell of polygon points
        [MaskPIV,~] = getFlyNRefMask((A+B)/2,camera,diln,thresh,minObjSize);
    else
        [~,MaskPIV] = getFlyNRefMask((A+B)/2,camera,diln,thresh,minObjSize);
    end
    s{4,2}=MaskPIV;         % If needed, generate via: imagesc(image); [temp,Mask{1,1},Mask{1,2}]=roipoly;
end

if setFliestoZero
    frmaskA = getFlyNRefMask(A,camera,diln,thresh,minObjSize);
    frmaskB = getFlyNRefMask(B,camera,diln,thresh,minObjSize);
    A(frmaskA) = 0;
    B(frmaskB) = 0;
end


% PIV analysis:
image1 = PIVlab_preproc (A,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2}); %preprocess images
image2 = PIVlab_preproc (B,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2});

% this addition is to avoid crash at the fft
if sum(image1(:))==0
    image1(1,1) = 5;
    image1(end,end) = 5;
end
if sum(image2(:))==0
    image2(50,50) = 5;
    image2(end-50,end-50) = 5;
end

% insert a try cath to bypass flat image calculation
try % attemp piv estimation
    [x, y, u, v, typevector] = piv_FFTmulti (image1,image2,s{1,2},s{2,2},s{3,2},s{4,2},s{5,2},s{6,2},s{7,2},s{8,2},s{9,2},s{10,2});
    
    %Remove values at the borders of the analysis: These are always less
    %reliable (because a part of the interrogation area is just blank), and
    %they deteriorate the result of this comparison without legal cause.
    u(:,1)=[];u(:,end)=[];u(1,:)=[];u(end,:)=[];
    v(:,1)=[];v(:,end)=[];v(1,:)=[];v(end,:)=[];
    x(:,1)=[];x(:,end)=[];x(1,:)=[];x(end,:)=[];
    y(:,1)=[];y(:,end)=[];y(1,:)=[];y(end,:)=[];
    typevector(:,1)=[];typevector(:,end)=[];typevector(1,:)=[];typevector(end,:)=[];
    
catch % if did not work set all to nan
    
    disp('piv calculation did not work.')
    x=NaN;y=x;u=x;v=x;typevector=x;
end




