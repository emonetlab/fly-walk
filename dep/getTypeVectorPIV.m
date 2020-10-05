function typevector = getTypeVectorPIV(A,B,parameters)

camera = parameters.camera;
s = parameters.s;  % PIV settings
p = parameters.p;  % Image pre-process settings


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

% PIV analysis:
image1 = PIVlab_preproc (A,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2}); %preprocess images
image2 = PIVlab_preproc (B,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2});

typevector = piv_TypeVector(image1,image2,s{1,2},s{2,2},s{3,2},s{4,2},s{5,2},s{6,2},s{7,2},s{8,2},s{9,2},s{10,2});

%Remove values at the borders of the analysis: These are always less
%reliable (because a part of the interrogation area is just blank), and
%they deteriorate the result of this comparison without legal cause.
typevector(:,1)=[];typevector(:,end)=[];typevector(1,:)=[];typevector(end,:)=[];

