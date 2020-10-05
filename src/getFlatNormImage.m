function p = getFlatNormImage(p,fitPoly,showfit)

switch nargin
    case 2
        showfit = 0; % show fitted surface on the image
    case 1
        showfit = 0; % show fitted surface on the image
        fitPoly = 1; % do not fit surface, use the median filtered image as the normalization image
end
% median filter and surface fit
n=50;  %median filter size
rlcrps = 120;
image = p.bkg_img.*makeFlatFieldMask(uint8(p.mask),rlcrps);
bcrps = p.crop_box.bcrp;
tcrps = p.crop_box.tcrp;

image = image(tcrps+1:end-bcrps-1,rlcrps+1:end-rlcrps-1);
image = medfilt2(image,[n,n]);      % median filter
image = smooth2a(double(image),50); % smooth

%%
if fitPoly % fit a 2D polynomial surface on the filtered image and use the fit as the flat image
    [height,width] = size(image);
    [X,Y] = meshgrid(1:width,1:height);
    X = X(:)+rlcrps;
    Y = Y(:)+tcrps;
    Z = double(image(:));
    [sf,gof] = fit([X,Y],Z,'poly55');

    z = feval(sf,[X,Y]); % evaluate the surface from the fit

    % reshape z
    flatImage = reshape(z,height,width);
    if showfit
        figure;
        plot(sf,[X,Y],Z)
    end
else % use the median filtered image
    flatImage = image;
end

%% normalize
flatImageN = flatImage./median(flatImage(:));
FlatNormImage = ones(size(p.bkg_img));
FlatNormImage(bcrps:bcrps+size(flatImageN,1)-1,rlcrps:rlcrps+size(flatImageN,2)-1) = flatImageN;

% put these in to parameter structure
p.FlatNormImage =  FlatNormImage;
p.FlatFitObj =  sf;
p.FlatFitGof =  gof;

