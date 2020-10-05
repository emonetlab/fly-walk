function Ifill = fillFlies(I,diln,thresh,minObjSize)
%fillFlies
%   fills the flies in the image by thresholding and interpolating
switch nargin
    case 3
        minObjSize = 100; % remove objects maller than this
    case 2
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
    case 1
        minObjSize = 100; % remove objects maller than this
        thresh = 0.2; % default 0.2
        diln = 5; % dilate by disk size of 4
    case 0
        help fillFLies
        error('where is image?')
end

mask = getFlyMask(I,diln,thresh,minObjSize);
Ifill = regionfill(I,mask); % fill it