function mask = makeFlatFieldMask(mask,npxlrl)
if nargin==1
    npxlrl = 100;
end
mask(:,1:npxlrl) = 0;
mask(:,end-npxlrl:end) = 0;