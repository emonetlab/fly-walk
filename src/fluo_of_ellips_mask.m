function fluo = fluo_of_ellips_mask(xymat_ellipse,img)

nopix = length(xymat_ellipse(:,1));
fluosum = 0;

for i = 1:nopix
    fluosum = fluosum + double(img(xymat_ellipse(i,2),xymat_ellipse(i,1)));
end

fluo = fluosum/nopix;