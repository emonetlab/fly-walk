function [fluo,fluo_list] = fluo_of_ellips_mask_f(xymat_ellipse,img)
% A bug was corrected: Previously, this function gave Nan values to the 
% of flies close to the boundaries.

nopix = length(xymat_ellipse(:,1));
fluosum = 0;


% FIX added:
if (nopix == 0)
    fluo = 0;
    return;
end
%
fluo_list = zeros(nopix,1);     % initiate fluorescence list

for i = 1:nopix
    fluosum = fluosum + double(img(xymat_ellipse(i,2),xymat_ellipse(i,1)));
    fluo_list(i) = double(img(xymat_ellipse(i,2),xymat_ellipse(i,1)));
end

fluo = fluosum/nopix; % This used to give Nan values: NO MORE!!! FIXED!

end