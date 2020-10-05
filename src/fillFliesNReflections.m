function [pxllist,mask,Ifill] = fillFliesNReflections(f,only_these_refs,diln)
% fillFliesNReflections
% fills the flies and the all possible reflections in the image by 
% creating a mask via thresholding and dilating. The mask is used to 
% fill the flies and reflections via inward interpolation
switch nargin
    case 2
        diln = 5;
    case 1
        diln = 5;
        only_these_refs = 'all';    % include all possible reflections in the mask
    case 0
        help fillFLies
        error('where is f?')
end

% get the fly and reflections mask
[mask,pxllist] = getFlyNRefMaskSigMeas(f,only_these_refs,diln);

Ifill = regionfill(f.current_raw_frame,mask); % fill it