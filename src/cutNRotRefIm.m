function RefMat = cutNRotRefIm(I,S)

cutsize = 100;
finalsize = 15;

RefMat = zeros(numel(S),(2*finalsize+1)^2);

for i = 1:numel(S)
    smallIm = cutImage(I,flip(S(i).RX),cutsize);
    smallIm = imrotate(smallIm,-(S(i).Orientation),'bilinear','crop');
    smallIm = cutImage(smallIm,ones(2,1)*(round(cutsize)+1),finalsize);
    RefMat(i,:) = smallIm(:);
end